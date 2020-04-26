#!/user/bin/perl

use strict;
use POSIX qw(strftime);

# mhl data
my %data;

&readData();

# population
my $N = 10000000;

# policy index map
sub getAlpha() {
	my $day = shift;
	
	# days of policy switch
	my @ds = (31, 49, 67, 74);
	# alpha for each policy span
	my @alphas = (0.25, 0.092, 0.155, 0.082, 0.058);
	
	my $index;
	if ($day < $ds[0]) {
		$index = 0;
	} elsif ($day < $ds[1]) {
		$index = 1;
	} elsif ($day < $ds[2]) {
		$index = 2;
	} elsif ($day < $ds[3]) {
		$index = 3;
	} else {
		$index = 4;
	}
	return $alphas[$index];
}

# infection probability. persons/(infected*day) for each policy index.

my $m = 10; # days to detection from infection.
my $n = 14; # days to heal from infection without sickness.
my $o = 21; # days to heal from detection.

my $infected = 5; # daily number of hidden infected in the town. let initial value be 5.
my $c_infected = $infected; # cummulative number of infected persons on this day.

my $rdetection = 0.1; # ratio of illness (and then isolated) to all infected.

my $detected = 0; # daily number of those newly diagnosed positive.
my $c_detected = 0; # cummulative number of detected positive.

my $isolated = 0; # number of isolated persons on the day.
 
my @toBeHealed; # future number of those healed on the day.
my @toBeDetected; # future number of those detedted on the day.
my @toRecover; # future number of those recover on the day.

my $i = 0; # day
while ($i < 200) {
	$i++;

	# figures of the day

	my $alpha = &getAlpha($i);
		
	# mass immunity factor
	my $r = ($N - $c_infected) / $N;
	if ($r < 0) {
		$r = 0;
	}
	
	# today's new infection
	my $infection = $infected * $alpha * $r;
	$infected += $infection;
	$c_infected += $infection;
	
	# number of those expected to be tested and found infected and isolated
	$toBeDetected[$i + $m] = $infection * $rdetection;
	
	# number of those who stay asymptomatic and are axpected to be healed.
	$toBeHealed[$i + $n] = $infection * (1 - $rdetection);

	# today's new detection
	my $detected = 0;
	if (defined $toBeDetected[$i]) {
		$detected = $toBeDetected[$i];
		$c_detected += $detected;
		$infected -= $detected;
		$isolated += $detected;
		$toRecover[$i + $o] = $detected;
	}
	
	# this many infected and not isolated are healed, $n days after infection.
	if (defined $toBeHealed[$i]) {
		$infected -= $toBeHealed[$i];
	}
		
	# exit from isolation
	if (defined $toRecover[$i]) {
		$isolated -= $toRecover[$i];
	}
	
	my $datestr = &serNo2Date($i);
	my $mhl = $data{$datestr};
	if (!defined $mhl) {
		$mhl = "";
	} 
	printf "%5.3f,%d,%s,%s,%d,%d,%d,%d,%d,%6.4f\n",
	 $alpha, $i, $datestr, $mhl, $infected, $detected, $c_detected, $isolated, $c_infected, $r;
}

sub readData() {
	while (<DATA>) {
		my @a = split " ";
		if (defined $a[1]) {
			$data{$a[1]} = $a[0];
		} else {
			$data{$a[0]} = "";
		}
	}
}

sub serNo2Date() {
	my $n = shift;
	my $epoch = 1579996800 + $n * 86400;
	my $datestr = strftime("%d/%m/%Y",localtime($epoch));
    return $datestr;            	                 
}

1;

# Japan mhl data for daily detected.
__DATA__
1	11/02/2020
	12/02/2020
4	13/02/2020
9	14/02/2020
4	15/02/2020
4	16/02/2020
6	17/02/2020
8	18/02/2020
8	19/02/2020
9	20/02/2020
	21/02/2020
	22/02/2020
	23/02/2020
	24/02/2020
	25/02/2020
	26/02/2020
	27/02/2020
20	28/02/2020
9	29/02/2020
15	01/03/2020
14	02/03/2020
16	03/03/2020
33	04/03/2020
31	05/03/2020
59	06/03/2020
47	07/03/2020
33	08/03/2020
26	09/03/2020
54	10/03/2020
52	11/03/2020
55	12/03/2020
40	13/03/2020
63	14/03/2020
33	15/03/2020
15	16/03/2020
44	17/03/2020
39	18/03/2020
36	19/03/2020
53	20/03/2020
34	21/03/2020
42	22/03/2020
38	23/03/2020
65	24/03/2020
93	25/03/2020
96	26/03/2020
104	27/03/2020
194	28/03/2020
173	29/03/2020
67	30/03/2020
220	31/03/2020
202	01/04/2020
235	02/04/2020
314	03/04/2020
336	04/04/2020
378	05/04/2020
248	06/04/2020
351	07/04/2020
499	08/04/2020
579	09/04/2020
656	10/04/2020
714	11/04/2020
530	12/04/2020
311	13/04/2020
457	14/04/2020
484	15/04/2020
503	16/04/2020
556	17/04/2020
556	18/04/2020
360	19/04/2020
361	20/04/2020
370	21/04/2020
420	22/04/2020
434	23/04/2020
423	24/04/2020
326 25/04/2020
