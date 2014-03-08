# Objects that check for violations based on a particular constraint on a
# process
package Configuration;

use Modern::Perl;
use Moose;
use MooseX::StrictConstructor;
use Readonly;
use IO::File;
use constant::boolean;
use Carp;
use Data::Dumper;

Readonly::Scalar my $CONFIG_PATH =>
    qr('~/.config/process-monitor/process-monitor.*');

# All ProcessConstraints in the configuration
has constraints => (
    is  => 'ro',
    isa => 'ArrayRef[ProcessConstraint]',
    required => TRUE,
#    builder => '_build_constraints',
    default => 0,
    lazy => TRUE,
);

# Configured sleep time
has sleep_time => (
    is  => 'ro',
    isa => 'Int',
    default => 5,
);

around BUILDARGS => sub {
    my ($orig, $class, @dummy) = @_;
    if (@dummy > 0 and defined $dummy[0]) {
        croak "Error: Code defect: '$class' constructor takes no " .
            "arguments\n[args passed: " . join(", ", @dummy) . ']';
    }
    # Build the constraints array ref here and set the 'constraints' attribute
    # to it via the original BUILDARGS method (i.e., $orig).
    my $constraints = [ProcessConstraint->new(mem_limit => 180 * 1024 * 1024)];
say "BA args: ", Dumper(@_);
    $class->$orig(constraints => $constraints, sleep_time => 1);
};

sub BUILD {
    my ($self) = @_;
say "BUILD - self: ", Dumper($self);
}

sub _build_constraints {
    my ($self) = @_;
say "_bc args: ", Dumper(@_);
    my $result = [ProcessConstraint->new( mem_limit => 180 * 1024 * 1024)];
#    $self->sleep_time(22);
#exit 37;
    $result;
}

2;
