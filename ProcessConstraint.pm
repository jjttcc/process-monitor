# Objects that check for violations based on a particular set of constraints
# on a process
package ProcessConstraint;

use Modern::Perl;
use Moose;
use MooseX::StrictConstructor;
use Data::Dumper;
use constant::boolean;
use Readonly;


Readonly::Scalar my $MB => 1024 * 1024;

# configured name of the constraint
has name => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { '' },
);

# regex patterns to be used to grep for a matching process
has patterns => (
    is      => 'ro',
    isa     => 'ArrayRef[Regexp]',
#    default => sub { [qr/\bchrome\b/i, qr/\bvlc\b/] },
    default => sub { [qr/\bfirefox\b/i, qr/\bhogmem\b/, qr/\bperl\b/] },
);

# memory-size limit
has mem_limit => (
    is      => 'ro',
    isa     => 'Int',
    default => sub {-1},
);

# cpu % limit
has cpu_limit => (
    is      => 'ro',
    isa     => 'Int',
    default => sub {-1},
);

# Reason last call to '_conforms' returned false [!!!!!remove??]
has _last_violation => (
    is      => 'rw',
    isa     => 'Str',
    default => sub {''},
);

# Action to be taken for violating processes
has action => (
    is => 'rw',
    isa => 'CodeRef',
# !!!use this one(?):    isa => 'ProcessAction',
#    default => sub { sub { my ($proc, $desc) = @_; say "[$desc]"; } }
    default => sub { \&report_violation },
);

# Inspect each element of $procs for process-limit violations and, for each
# process $p for which there is a violation, run $self->action($p).
sub process_violations {
    my ($self, $procs) = @_;

    my @candidates = grep {
        my $match = FALSE;
        for my $p (@{$self->patterns}) {
            if ($_->cmndline =~ $p or $_->fname =~ $p) {
                $match = TRUE;
                last;
            }
        }
        $match;
    } @{$procs};
    for my $proc (@candidates) {
#printf("%s: %0.1f MB [%s]\n", $proc->fname, $proc->rss / $MB, $proc->cmndline);
       if (not $self->_conforms($proc)) {
           $self->action->($proc, $self->_last_violation);
       }
    }
}

sub report_violation {
    my ($proc, $desc) = @_;
    printf("Process %d [%s] violates constraint:\n", $proc->pid,
        $proc->fname);
    printf("%s\n", $desc);
}

#####  Implementation (non-public)

# Does $proc conform to this object's constraints?  If not (i.e., FALSE),
# _last_violation is set to a description of $proc's violation.
sub _conforms {
    my ($self, $proc) = @_;
    my $result = TRUE;
    if ($self->mem_limit >= 0 and $proc->rss > $self->mem_limit) {
        $self->_last_violation('memory/rss limit: ' .
            $proc->rss / 1024 . ' > ' . $self->mem_limit / 1024);
        $result = FALSE;
    }
    $result;
}

2;
