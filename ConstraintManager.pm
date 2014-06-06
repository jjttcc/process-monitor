# Manager of constraint-checking logic
# Copyright 2014  Jim Cochrane - GNU GPL, verson 2
package ConstraintManager;

use Modern::Perl;
use Moose;
use MooseX::StrictConstructor;
use Data::Dumper;
use constant::boolean;
use Readonly;

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
        # Sleep first in case this application is configured to be monitored -
        # Start-up (compiling/initializing/...) takes a very large amount of
        # CPU time compared with after start-up has finished.  Thus this
        # prevents what could be considered a false positive.
        sleep $self->configuration->sleep_time;
        # ([Re-]read configuration each time in case it was changed.)
        $self->configuration->parse_config_files();
        $self->check_processes();
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
}

1;
