
use Modern::Perl;
use constant::boolean;
use Proc::ProcessTable;
use Data::Dumper;
use ProcessConstraint;
use ConstraintManager;

package main;

my $mb = 1024*1024;
my $mgr = ConstraintManager->new();
$mgr->execute();
