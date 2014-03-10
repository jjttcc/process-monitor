
use Modern::Perl;
use constant::boolean;
use Proc::ProcessTable;
use Data::Dumper;
use ProcessConstraint;
use ConstraintManager;
use Configuration;
use Action;
use ReportAction;
use EmailAction;
use KillAction;

package main;

my $mgr = ConstraintManager->new();
$mgr->execute();
