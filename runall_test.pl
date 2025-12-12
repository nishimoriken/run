#!/usr/bin/perl
use Getopt::Long;
use strict;
use lib qw(./);
require "runall_util.pl";
$| = 1;

# Time-stamp: <2025-12-12 16:22:17 nishimoriken>

##########################################################################
# edit
##########################################################################

### Timeout (sec.)
my $timeout = 10;
# my $timeout = 40;
# my $timeout = 60;
# my $timeout = 2*60;
# my $timeout = 3*60;
# my $timeout = 5*60;
# my $timeout = 10*60;
# my $timeout = 15*60;
# my $timeout = 16*60;
# my $timeout = 30*60;
# my $timeout = 1*60*60;
# my $timeout = 2*60*60;
# my $timeout = 3*60*60;
# my $timeout = 24*60*60;

### ASP encoding
my %encoding = ();
$encoding{""} = "";

### Solver

my %solver = ();

$solver{"cfb"} = "./target/release/cfb";
my $bound = "100";

### Others
my $date  = "/bin/date";
my $time  = "/usr/bin/time";

##########################################################################

### Options
my ($opt_n, $opt_h, $opt_d);
&GetOptions('n|noexec' => \$opt_n, 'h|help' => \$opt_h, 'd|dir=s' => \$opt_d);
if ($opt_h) { &usage(); }

### Inputs
die if (@ARGV != 1 || ! -e $ARGV[0]);
my $input = $ARGV[0];

### Outputs
my $timestamp = `$date "+%Y-%m-%d-%H-%M-%S"`;
chomp($timestamp);
my $prefix = "result/$timestamp";
if ($opt_d) {
    $prefix = $opt_d;
}
my $log_dir = "$prefix/log";
my @dirs = ($log_dir);
my $copy_input  = "$prefix/BENCH.csv";

### Main
&exec("mkdir -p $prefix");
&exec("cp $input $copy_input");
foreach my $d (@dirs) {
    if (! -e $d) {
	&exec("mkdir -p $d");
    }
}

&read_list($input);
my @list = &get_list();

print "\nSTART solving problems in $input\n";
foreach my $p (@list) {
    foreach my $enc (keys %encoding) {
	foreach my $slv (keys %solver) {
	    &solve($p, $enc, $slv);
	}
    }
}
print "FINISH solving problems in $input\n";
print "See $prefix\n";

exit 0;

sub solve {
    my ($p, $enc, $slv) = @_;
    my ($problem, $fact) = @{$p};
    my $log = &make_file_name($log_dir, $problem, $enc, $slv) . ".log";
    my $id  = join(" ", ($problem, $enc, $slv));
    my $skip = 0;
    if (-e $log) {
	$skip = 1;
	my %r = &read_log($log);
	foreach my $x (keys %r) {
	    print "$x:\t" . $r{$x} . "\n";
	}
	if (! $r{'RESULT'}) {
	    $skip = 0;
	} elsif ($r{'RESULT'} eq "OPTIMUM") {
	    $skip = 1;
	} elsif ($r{'RESULT'} eq "UNSAT") {
	    $skip = 1;
	} elsif ($r{'TIMELIMIT'} && $r{'Time'} < $timeout) {
	    $skip = 0;
	}
    }
    if ($skip) {
	print "# skip $id\n";
	next;
    }
    print "BEGIN $id [", scalar(localtime), "]\n";
    &run($fact, $enc, $slv, $log);
    print "END $id [", scalar(localtime), "]\n";
    print "\n";
}

sub run {
    my ($fact, $enc, $slv, $log) = @_;
    my $time_limit = "--time-limit=$timeout";
    my $cmd2 = join(" ", ($solver{$slv}, $encoding{$enc}, $fact, $time_limit));
    print "$cmd2\n";
    if ($opt_n) {
	return;
    }
    open(LOG, ">$log") || die("$!");
    my $old = select; select(LOG); $| = 1; select($old);
    open(CMD, "$cmd2 2>&1 |") || die;
    my $state = 0;
    while (<CMD>) {
	print LOG $_;
	if ($state == 0) {
	    if (/^SATISFIABLE/) {
		print $_;
		$state = 1;
	    } elsif (/^UNSATISFIABLE/) {
		print $_;
		$state = 1;
	    } elsif (/^UNKNOWN/) {
		print $_;
		$state = 1;
	    } elsif (/^OPTIMUM FOUND/) {
		print $_;
		$state = 1;
	    } elsif (/^s (?:\[.*?\] )?SATISFIABLE/) {
		print $_;
		$state = 2;
	    } elsif (/^s (?:\[.*?\] )?UNSATISFIABLE/) {
		print $_;
		$state = 2;
	    } elsif (/^s (?:\[.*?\] )?UNKNOWN/) {
		print $_;
		$state = 2;
	    } elsif (/^s (?:\[.*?\] )?OPTIMUM FOUND/) {
		print $_;
		$state = 2;
	    } elsif(/^Costs:/) {
		print $_;
	    } elsif (/OPTIMAL SOLUTION FOUND/) {
		print $_;
	    }
	} elsif ($state == 1) {
	    if (/Optimization\s*:/) {
		print $_;
	    }
	} elsif ($state == 2) {
	    if (/^a (?:\[.*?\] )?Optimization:/) {
		print $_;
	    }
	}
    }
    close(CMD);
    close(LOG);
}

sub exec {
    my ($cmd) = @_;
    print "$cmd\n";
    if (! $opt_n) {
	system($cmd);
    }
}

sub usage {
    print "\nUsage: $0 [options] benchmark.csv\n";
    print "\nParameters:\n";
    print "\t-h  : print this help\n";
    print "\t-n  : no exec\n";
    print "\t-d  : specify a prefix directory\n";
    print "\n";
    exit(1);
}
