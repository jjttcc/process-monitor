package KillAction;
# Process-killing actions

use Modern::Perl;
use Moose;
use Sys::Hostname;
use Carp;
use Data::Dumper;

extends ('Action');

# Kill $proc->pid.
sub execute {
    my ($self, $proc) = @_;
#say "I've been ordered to kill process ", $proc->pid, ", but I won't do it.";
#exit 23;
    my $pid = fork();
    if ($pid != 0) {
        # (in parent)
    } elsif ($pid == 0) {
        # (in child)
        my $target_pid = $proc->pid;
        my $sleep = 'sleep 3';
        # (The 2nd kill [with -9] is intended to force the murder to take
        # place in case the 1st kill fails.)
        my $cmd = "kill $target_pid; $sleep; kill -9 $target_pid 2>/dev/null";
        exec 'sh', '-c', $cmd;
        exit 0;
    } else {
        carp "fork of email process failed: $!\n";
    }
    # Wait for the child process to end:
    my $tmp = waitpid($pid, 0);
}


1;
