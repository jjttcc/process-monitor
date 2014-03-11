# Actions to be taken as the result of a process constraint violation
# Copyright 2014  Jim Cochrane - GNU GPL, verson 2
package Action;

use Modern::Perl;
use Moose;
use Data::Dumper;


# configuration
has config => (
    is  => 'rw',
    isa => 'Configuration',
);

# Execute the action.
sub execute {
    my ($self, $proc, $violation_desc) = @_;
    say "execute called on ", Dumper($self);
}

1;
