# Actions that report a constraint violation via email
# Copyright 2014  Jim Cochrane - GNU GPL, verson 2
package EmailAction;

use Modern::Perl;
use Moose;
use Sys::Hostname;
use DateTime;
use Carp;
use Data::Dumper;

extends ('Action');

# Execute the action.
sub execute {
    my ($self, $proc, $desc) = @_;
    my $subject = sprintf("Process violation on %s [%s]",
        hostname, $proc->fname);
    my $msg = sprintf("Process %d [%s] violates constraint [%s]:\n%s\n",
        $proc->pid, $proc->fname,
        DateTime->now(time_zone => $self->config->timezone), $desc);
    my $addrs = join(' ', @{$self->config->email_addrs});
    $self->send_mail($self->config->email_addrs, $subject, $msg);
}


# Send the specified email message to the specified addresses.
sub send_mail {
    my ($self, $addrs, $subject, $msg) = @_;
    my $pid = fork();
    if ($pid != 0) {
        # (in parent)
    } elsif ($pid == 0) {
        # (in child)
        open my $emailproc, '|-', 'mutt', "-s $subject", @$addrs or
            die "email process failed: $!";
        print {$emailproc} "$msg\n";
        close($emailproc) or die "can't close email process $!";
        exit 0;
    } else {
        carp "fork of email process failed: $!\n";
    }
    # Wait for the child process to end:
# !!!!!might be good to delete this - i.e., not wait:
    my $tmp = waitpid($pid, 0);
}


1;
