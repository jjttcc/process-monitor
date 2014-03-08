
use Modern::Perl;
use constant::boolean;
use Proc::ProcessTable;
use Data::Dumper;
use ProcessConstraint;
use ConstraintManager;
use Configuration;

package main;

my $mgr = ConstraintManager->new();
$mgr->execute();
