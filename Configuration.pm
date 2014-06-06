# Objects that check for violations based on a particular constraint on a
# process
# Copyright 2014  Jim Cochrane - GNU GPL, verson 2
package Configuration;

use Modern::Perl;
use Moose;
use MooseX::StrictConstructor;
use Readonly;
use IO::File;
use boolean;
use feature 'state';
use Carp;
use Data::Dumper;

Readonly::Scalar my $CONFIG_PATH_PATTERN =>
    '~/.config/process-monitor/process-monitor*';

# All ProcessConstraints in the configuration
has constraints => (
    is  => 'rw',
    isa => 'ArrayRef[ProcessConstraint]',
    required => true,
    default => 0,
    lazy => true,
);

# Configured sleep time
has sleep_time => (
    is  => 'rw',
    isa => 'Int',
    default => 5,
);

# email addresses to which notifications are to be sent
has email_addrs => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
);

# Time zone, for display of local date/time
has timezone => (
    is  => 'rw',
    isa => 'Str',
);

# Filename => modification-time - for each configuration file
has config_file_times => (
    is  => 'rw',
    isa => 'HashRef',
);

# Parse the configuration files.  If this method is being called for the first
# time, parse all files unconditionally; otherwise, parse only the files that
# have changed since the file was last parsed.
sub parse_config_files {
    my ($self) = @_;
    my @files = glob($CONFIG_PATH_PATTERN);
    my $parse_needed = true;
    if (defined $self->config_file_times) {
        $parse_needed = false;
        use constant MODTIMEIDX => 9;
        # Obtain a new file list in case any new ones have been added.
        my @files = glob($CONFIG_PATH_PATTERN);
        my $ftimes = $self->config_file_times;
        for my $fname (@files) {
            if (-r $fname) {
                my $modtime = DateTime->from_epoch(
                    epoch => (stat $fname)[MODTIMEIDX]);
                my $old_modtime = $ftimes->{$fname};
                if (not defined $old_modtime or $modtime > $old_modtime) {
                    # Either a new config file has been found or one of the
                    # existing config files ($fname) has changed - Indicate
                    # that a (re-)parse is needed and end the loop.  (All
                    # config files will be parsed again to ensure that no old,
                    # obsolete settings are still in effect.)
                    $parse_needed = true;
                    last;
                }
            } else {
                warn "config file $fname is not readable";
            }
        }
    }
    if ($parse_needed) {
        my $ftimes = {};
        for my $f (@files) {
            my $modtime = DateTime->from_epoch(
                epoch => (stat $f)[MODTIMEIDX]);
            $ftimes->{$f} = $modtime;
        }
        $self->config_file_times($ftimes);
    }
    $self->_configure();
}


#####  Implementation (non-public)

# Parse/re-parse the configuration files (found in config_file_times) and set
# up the configuration accordingly.
sub _configure {
    my ($self) = @_;
    $self->process_config_lines($self->_config_file_contents());
}

# Process configuration (@$lines) and set the variables $constraints,
# $sleep_time, etc. accordingly.
sub process_config_lines {
    my ($self, $lines) = @_;
    my $constraints = [];
    my $emails = [];
    my ($timezone, $sleep_time);
    my $i = 0;
    while ($i < @$lines) {
        my $line = $lines->[$i];
        given ($line) {
            when (/(^#|^$)/) { continue }
            when (/^sleep/) {
                $sleep_time = sleeptime_from($line)
            }
            when (/^emailaddr/) {
                my $field = field_from($line, 2);
                if ($field ne '') {
                    push @$emails, $field;
                }
            }
            when (/^timezone/) {
                my $field = field_from($line, 2);
                # (If there be more than one timezone, the last one
                # encountered will be used.)
                if ($field ne '') {
                    $timezone = $field;
                }
            }
            when (/^constraint/) {
                my $c;
                ($c, $i) = $self->parsed_constraint($lines, $i);
                push @$constraints, $c;
            }
            default {
                continue
            }
        }
        ++$i;
    }
    # (sleep-time of 0 is a bad idea.)
    if ($sleep_time == 0) { $sleep_time = 1; }
    $self->sleep_time($sleep_time);
    $self->timezone($timezone);
    $self->email_addrs($emails);
    $self->constraints($constraints);
}

# A new ProcessConstraint built with the constraint values specified beginning
# at the current position (specified by $i) of $lines, along with the new
# value of index $i (set to the index of the element of $lines corresponding
# to the end of the current constraint definition.
sub parsed_constraint {
    my ($self, $lines, $origi) = @_;
    my $i = $origi;
    my (undef, $name) = split(' ', $lines->[$i]);
    ++$i;
    my $in_constraint = true;
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
            }
            when (/^end/) {
                $in_constraint = false;
            }
            default { continue }
        }
        ++$i if $in_constraint;
    }
    for my $a (@$actions) {
        $a->config($self);
    }
    (ProcessConstraint->new(name => $name, patterns => $patterns,
        mem_limit => $mem, cpu_limit => $cpu, actions => $actions), $i);
}

sub _config_file_contents {
    my ($self) = @_;
    my @config_files = keys $self->config_file_times;
    my $result = [];
    for my $f (@config_files) {
        my $file = IO::File->new($f, 'r');
        if (defined $file) {
            push @$result, <$file>;
        }
    }
    chomp @$result;
    $result;
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
