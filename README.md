process-monitor
===============

A simple perl script to monitor running processes on Linux systems and
execute a set of configured actions based on process "violations"

Synopsis
===============

    process-monitor

Description
===============

process-monitor is a fairly simple script that reads a configuration file
(located in $HOME/.config/process-monitor/ and named with the glob pattern
process-monitor\*) - which specifies process constraints, resulting
actions, etc. - and continually checks on all running processes, sleeping
for a specified time in between each check, and, for any processes that
are found to be in violation of the constraints, executes a set of
configured actions with respect to all violating processes.

Configuration File
===============
You can use the example config file, process-monitorrc, to get started with
creating your own config file.

Global tags/settings:
---------------

* sleep-time - seconds to sleep between process checks
* emailaddr  - address to send email warnings to (more than one can be
specified)

Example:

    sleep-time  60
    emailaddr   me@me.com

Constraints
---------------

A process constraint is specified in a multi-line section - starting with
the line:

constraint: `<name>`  

(where `<name>` is an (optional) name for the constraint) and ending with
the line:

end

The following constraint parameters are available - each one specified on
a separate line:

* _memlimit_ - memory (rss) limit, in bytes
* _cpulimit_ - cpu percentage limit (floating-point value)
* _pattern_ - regular expression pattern that will be used to search for a
matching process (by either the process filename or the command-line)
* _action_ - action to take when a constraint violation is detected

The _pattern_ parameter is used to find matching processes upon which the
constraint specifications will be checked.  One or more patterns may be
specified for a particular process constraint.  If none are specified, no
checking will be performed, since no matches will be found.

The _memlimit_ and _cpulimit_ tags are used to define rules by which each
matching (by _pattern_) process will be checked.  These two tags are
the only process rules currently implemented.  (Others may be added later.)
Either one or both may be specified for a particular process constraint.

The _action_ parameter should be one of the following:

* _email_ - A warning email will be sent to the configured _emailaddr_s.
* _report_ - A report about the violation will be output on the controlling
terminal.
* _kill_ - The violating processes will be killed.

Any line starting with # will be ignored (i.e., treated as a comment).

Example:

    constraint: chrome
    # memory (rss) limit, in bytes:
    memlimit    250000000
    # cpu percentage limit:
    cpulimit    25
    pattern     \bchrome\b
    pattern     \bgoogle-chrome\b
    action      email
    action      kill
    end

License:  GNU GPL, verson 2
===============

Copyright 2014  Jim Cochrane - GNU GPL, verson 2 (See the LICENSE file
for the details.)

Dependencies
===============

Modern::Perl  
Moose  
MooseX::StrictConstructor  
Proc::ProcessTable  
Sys::Hostname  

Platforms and Portability
===============

Since process-monitor depends on Proc::ProcessTable, which accesses the
UNIX process table, it will probably not be portable to Windows without
some major changes.  It has been tested on Linux, but may run on other
UNIXes with few to no changes.

Installation
===============
The easy way
---------------
Grab all the files from this repository and run the build script:

./build

to build the process-monitor script from the \*.pm files.  To run the
application, make sure process-monitor is in the current directory and,
from the command line, enter:

./process-monitor

or make sure process-monitor is in your path so that you can run the app by
typing (from the command line) 'process-monitor'. (E.g., put $HOME/bin in
your path and move the process-monitor file to $HOME/bin.)

The harder, cleaner way
---------------
Put all the \*.pm files in an appropriate place and set your system up so
that the other \*.pm files will be found when you run the main.pm script with:

perl main.pm

This is harder, of course, because I don't provide a script to automate this
procedure, nor do I provide detailed instructions.  If you're not a perl
geek and want to use this method, find a perl geek somewhere and ask for
help.

Configuration
---------------
Modify the process-monitorrc to fit your needs and then copy or move it to
the directory $HOME/.config/process-monitor/.  If this directory doesn't
exist, of course, it should be created before moving the file.
