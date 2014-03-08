# Manager of constraint-checking logic
package ConstraintManager;

use Modern::Perl;
use Moose;
use MooseX::StrictConstructor;
use Data::Dumper;
use constant::boolean;
use Readonly;

Readonly::Scalar my $MB => 1024 * 1024;

has process_table => (
    is  => 'rw',
    isa => 'Proc::ProcessTable',
);

has configuration => (
    is  => 'rw',
    isa => 'Configuration',
);

#####  Public interface

# Perform configured process-contraint-checking logic.
sub execute {
    my ($self) = @_;
    while (TRUE) {
        $self->check_processes();
        sleep $self->configuration->sleep_time;
    }
}

sub check_processes {
    my ($self) = @_;
    my $procs = $self->process_table->table;
    for my $constraint (@{$self->configuration->constraints()}) {
        $constraint->process_violations($procs);
    }
}


#####  Implementation (non-public)

sub BUILD {
    my ($self) = @_;
    $self->configuration(Configuration->new());
    $self->process_table(Proc::ProcessTable->new());
say Dumper($self->configuration);
}

1;
