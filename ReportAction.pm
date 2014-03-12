# Actions that report a constraint violation on the controlling terminal
# Copyright 2014  Jim Cochrane - GNU GPL, verson 2
package ReportAction;

use Modern::Perl;
use Moose;
use DateTime;
use Data::Dumper;

extends ('Action');

# Execute the action.
sub execute {
    my ($self, $proc, $desc) = @_;
    printf("Process %d [%s] violates constraint [%s]:\n", $proc->pid,
        $proc->fname, DateTime->now(time_zone => $self->config->timezone));
    printf("%s\n", $desc);
}

1;
