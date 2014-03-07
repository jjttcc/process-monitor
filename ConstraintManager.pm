# Manager of constraint-checking logic
package ConstraintManager;

use Modern::Perl;
use Moose;
use Data::Dumper;
use constant::boolean;
use Readonly;

Readonly::Scalar my $MB => 1024 * 1024;

has constraints => (
    is  => 'rw',
    isa => 'ArrayRef[ProcessConstraint]',
);

has patterns => (
    is  => 'rw',
    isa => 'ArrayRef',
);

has process_table => (
    is  => 'rw',
    isa => 'Proc::ProcessTable',
);

#####  Public interface

# Perform configured process-contraint-checking logic.
sub execute {
    my ($self) = @_;
    while (TRUE) {
        $self->check_processes();
        sleep 5;
    }
}

sub check_processes {
    my ($self) = @_;
    my @candidates = grep {
        my $match = FALSE;
        for my $p (@{$self->patterns}) {
            if ($_->cmndline =~ $p or $_->fname =~ $p) {
                $match = TRUE;
                last;
            }
        }
        $match;
    } @{$self->process_table->table};
    for my $proc (@candidates) {
        printf("%s: %0.1f MB [%s]\n", $proc->fname, $proc->rss / $MB,
            $proc->cmndline);
        for my $constraint (@{$self->constraints()}) {
            if (not $constraint->conforms($proc)) {
                printf("Process %d [%s] violates constraint:\n", $proc->pid,
                    $proc->fname);
                printf("%s\n", $constraint->last_violation);
            }
        }
    }
}


#####  Implementation (non-public)

sub BUILD {
    my ($self) = @_;
    my @patterns = ();
    if (@ARGV > 0) {
        @patterns = map { qr/$_/} @ARGV;
    } else {
        @patterns = (qr/\bchrome\b/i, qr/\bvlc\b/);
    }
    $self->patterns(\@patterns);
    $self->process_table(Proc::ProcessTable->new());
    $self->constraints([ProcessConstraint->new(memlimit => 111 * 1024 * 1024)]);
}

1;
