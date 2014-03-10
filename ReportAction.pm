package ReportAction;

use Modern::Perl;
use Moose;
use Data::Dumper;

extends ('Action');

# Execute the action.
sub execute {
    my ($self, $proc, $desc) = @_;
#say "execute called on ", Dumper($self);
    printf("Process %d [%s] violates constraint:\n", $proc->pid, $proc->fname);
    printf("%s\n", $desc);
}

1;
