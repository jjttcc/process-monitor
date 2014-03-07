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

1;
