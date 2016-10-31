# http://stackoverflow.com/a/5823645/90123

use v5.10;

use Cwd 'abs_path';
use File::Basename;

my $dirname = dirname(abs_path($0));

my $pid = fork();
if (not defined $pid) {
    die 'resources not available';
} elsif ($pid == 0) {
    # CHILD
    setpgrp;
    my @argv = @ARGV;
    push @argv, getppid();
    system(@argv) == 0 || die "Cannot run [$argv[0]].";
} else {
    # PARENT
    wait;
    my $child_status = $?;
    exit $child_status;
}
