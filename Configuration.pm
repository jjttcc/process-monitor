# Objects that check for violations based on a particular constraint on a
# process
package Configuration;

use Modern::Perl;
use Moose;
use MooseX::StrictConstructor;
use Readonly;
use IO::File;
use constant::boolean;
use feature 'state';
use Carp;
use Data::Dumper;

Readonly::Scalar my $CONFIG_PATH =>
    '~/.config/process-monitor/process-monitor*';

# All ProcessConstraints in the configuration
has constraints => (
    is  => 'ro',
    isa => 'ArrayRef[ProcessConstraint]',
    required => TRUE,
    default => 0,
    lazy => TRUE,
);

# Configured sleep time
has sleep_time => (
    is  => 'ro',
    isa => 'Int',
    default => 5,
);

# Configured sleep time
has email_addrs => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
);


#####  Implementation (non-public)

{
my $constraints;
my $sleep_time;
my $emails;
my @all_actions;

around BUILDARGS => sub {
    my ($orig, $class, @dummy) = @_;
    if (@dummy > 0 and defined $dummy[0]) {
        croak "Error: Code defect: '$class' constructor takes no " .
            "arguments\n[args passed: " . join(", ", @dummy) . ']';
    }
    @all_actions = ();
    my @config_lines = _config_file_contents();
# !!!!say "clines: ", Dumper(@config_lines);
    # Build the constraints array ref here and set the 'constraints' attribute
    # to it via the original BUILDARGS method (i.e., $orig).
#    my $constraints = [ProcessConstraint->new(mem_limit => 180 * 1024 * 1024)];
    process_config_lines(\@config_lines);
    my $result = $class->$orig(constraints => $constraints, sleep_time =>
        ($sleep_time <= 0? 1: $sleep_time, email_addrs => $emails));
    $result;
};

sub BUILD {
    my ($self) = @_;
    for my $a (@all_actions) {
        $a->config($self);
    }
}

sub process_config_lines {
    my ($lines) = @_;
#$constraints = [ProcessConstraint->new(mem_limit => 180 * 1024 * 1024)];
    $constraints = [];
    $emails = [];
    my $i = 0;
    while ($i < @$lines) {
        my $line = $lines->[$i];
        given ($line) {
            when (/(^#|^$)/) { continue }
            when (/^sleep/) { 
                $sleep_time = sleeptime_from($line)
            }
            when (/^emailaddr/) { 
                my $e = field_from($line, 2);
                if ($e ne '') {
                    push @$emails, $e;
                }
            }
            when (/^constraint/) { 
                my $c;
                ($c, $i) = parsed_constraint($lines, $i);
                push @$constraints, $c;
            }
            default {
                continue
            }
        }
        ++$i;
    }
}

# A new ProcessConstraint built with the constraint values specified beginning
# at the current position (specified by $i) of $lines, along with the new
# value of index $i (set to the index of the element of $lines corresponding
# to the end of the current constraint definition.
sub parsed_constraint {
    my ($lines, $origi) = @_;
    my $i = $origi;
    my (undef, $name) = split(' ', $lines->[$i]);
    ++$i;
    my $in_constraint = TRUE;
    my $patterns = [];
    my $actions = [];
    my ($mem, $cpu) = (-2, -2);
    while ($i < @$lines and $in_constraint) {
        my ($tag, $value) = split(' ', $lines->[$i]);
        given ($tag) {
            when (/^memlimit/) { 
                $mem = $value;
            }
            when (/^cpulimit/) { 
                $cpu = $value;
            }
            when (/^pattern/) { 
                push @$patterns, qr/$value/;
            }
            when (/^action/) { 
                my $type = field_from($lines->[$i], 2);
                my $action = new_action($type);
                push @$actions, $action;
                push @all_actions, $action;
            }
            when (/^end/) { 
                $in_constraint = FALSE;
            }
            default { continue }
        }
        ++$i if $in_constraint;
    }
    (ProcessConstraint->new(name => $name, patterns => $patterns,
        mem_limit => $mem, cpu_limit => $cpu, actions => $actions), $i);
}

}

sub _config_file_contents {
    my @result = ();
    my @files = glob($CONFIG_PATH);
    for my $f (@files) {
        my $file = IO::File->new($f, 'r');
        push @result, <$file>;
    }
    chomp @result;
    @result;
}

# The nth (specified with $fieldnum [starting at 1]) field of $line - empty
# string if there is no $fieldnum field in $line.
sub field_from {
    my ($line, $fieldnum) = @_;
    my $result = '';
    my @parts = split(' ', $line);
    my $i = $fieldnum - 1;
    if (@parts > $i) {
        $result = $parts[$i];
    }
    $result;
}

# sleep_time value extracted from $line
sub sleeptime_from {
    my ($line) = @_;
    my $result = field_from($line, 2);
    if ($result !~ /^\d+$/) {
        $result = -1;
    }
    $result;
}

sub new_action {
    my ($type) = @_;
    my $result;
    state $action_for = {
        email => sub { EmailAction->new() },
        kill  => sub { KillAction->new() },
    };
    my $builder = $action_for->{$type};
    if (defined $builder) {
        $result = $builder->();
    } else {
        # Default to ReportAction.
        $result = ReportAction->new();
    }
    $result;
}

2;
