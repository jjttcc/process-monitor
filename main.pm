
use Modern::Perl;
use constant::boolean;
use Proc::ProcessTable;
use Data::Dumper;
use ProcessConstraint;
use ConstraintManager;

package main;

my $mb = 1024*1024;
my $mgr = ConstraintManager->new();
for my $proc (@{$mgr->process_candidates()}) {
    printf("%s: %0.1f MB [%s]\n", $proc->fname, $proc->rss / $mb,
        $proc->cmndline);
    for my $constraint (@{$mgr->constraints()}) {
        if (not $constraint->conforms($proc)) {
            printf("Process %d [%s] violates constraint:\n", $proc->pid,
                $proc->fname);
            printf("%s\n", $constraint->last_violation);
        }
    }
}
