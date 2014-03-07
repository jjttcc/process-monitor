# Objects that check for violations based on a particular constraint on a
# process
package ProcessConstraint;

use Modern::Perl;
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

2;
