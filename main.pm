#!/usr/bin/env perl
# Monitor (and, optionally, act on) processes matching a configuration.

use Modern::Perl;
use constant::boolean;
use Proc::ProcessTable;
use Data::Dumper;


# Objects that check for violations based on a particular constraint on a
# process
package ProcessConstraint;

use Moose;
use Data::Dumper;
use constant::boolean;

# memory-size limit
has memlimit => (
	is      => 'ro',
	isa     => 'Int',
	default => sub {-1},
);

# Reason last call to 'conforms' returned false
has last_violation => (
	is      => 'rw',
	isa     => 'Str',
	default => sub {''},
);

sub conforms {
	my ($self, $proc) = @_;
	my $result = TRUE;
	if ($self->memlimit >= 0 and $proc->rss > $self->memlimit) {
		$self->last_violation('memory/rss limit: ' .
            $proc->rss / 1024 . ' > ' . $self->memlimit / 1024);
		$result = FALSE;
	}
	$result;
}


# Manager of constraint-checking logic
package ConstraintManager;

use Moose;
use Data::Dumper;
use constant::boolean;

has constraints => (
    is  => 'rw',
    isa => 'ArrayRef[ProcessConstraint]',
);

has patterns => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
);

has process_candidates => (
    is  => 'rw',
    isa => 'ArrayRef',
);

sub BUILD {
    my ($self) = @_;
    my $patterns = [];
    if (@ARGV > 0) {
        $patterns = \@ARGV;
    } else {
        $patterns = [qr/\bchrome\b/i, qr/\bvlc\b/];
    }
    $self->patterns($patterns);

    my $proctable = Proc::ProcessTable->new();
    my @candidates = grep {
        my $match = FALSE;
        for my $p (@$patterns) {
            if ($_->cmndline =~ $p or $_->fname =~ $p) {
                $match = TRUE;
                last;
            }
        }
        $match;
    } @{$proctable->table};
    $self->constraints([ProcessConstraint->new(memlimit => 111 * 1024 * 1024)]);
    $self->process_candidates(\@candidates);
}

package main;

my $mb = 1024*1024;
my $mgr = ConstraintManager->new();
for my $proc (@{$mgr->process_candidates()}) {
    printf("%s: %0.1f MB [%s]\n", $proc->fname, $proc->rss / $mb,
        $proc->cmndline);
    for my $constraint (@{$mgr->constraints()}) {
        if (not $constraint->conforms($proc)) {
            printf("Process %d [%s] violates constraint:\n", $proc->pid,
                $proc->fname);
            printf("%s\n", $constraint->last_violation);
        }
    }
}
