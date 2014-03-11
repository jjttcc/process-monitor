# Actions that report a constraint violation on the controlling terminal
# Copyright 2014  Jim Cochrane - GNU GPL, verson 2
package ReportAction;

use Modern::Perl;
use Moose;
use Data::Dumper;

extends ('Action');

# Execute the action.
sub execute {
    my ($self, $proc, $desc) = @_;
    printf("Process %d [%s] violates constraint:\n", $proc->pid, $proc->fname);
    printf("%s\n", $desc);
}

1;
