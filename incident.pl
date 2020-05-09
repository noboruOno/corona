#!/user/bin/perl

use strict;
use POSIX qw(strftime);
use Math::Trig 'pi';

my $sigma = 3;
my $sigma2 = 2 * $sigma * $sigma;
my $D = sqrt(2 * pi) * $sigma;

if ($#ARGV != 0) {
	print "usage: incident.pl <DATA FILE>\n";
	exit 1;
}

# mhl data
my %data;
my @serDate;

&readData($ARGV[0]);

my $delay = 10;
for (my $i = 0; $i <= $#serDate; $i++) {
	if (!defined $serDate[$i + $delay]) {
		last;
	}
	my $x = &integrate($i + $delay);
	my $datavalue = $data{$serDate[$i]};
	if (!defined $datavalue) {
		$datavalue = 0;
	}
	printf "%s, %5d, %7.3f\n", $serDate[$i], $datavalue, $x;
}

1;

sub integrate() {
	my $n = shift;
	
	my $sum = 0;
	my $i = 0;
	for (my $i = 0; $i <= $#serDate; $i++) {
		my $v = $data{$serDate[$i]};
		if (!defined $v) {
			$v = 0;
		}
		my $x = &distribution($n - $i, $v);
		$sum += $x;
	}
	
	return $sum;
}

# 1579996800 -> Sunday, January 26, 2020 9:00:00 AM GMT+09:00
sub serNo2Date() {
	my $n = shift;
	my $epoch = 1579996800 + $n * 86400;
	my $datestr = strftime("%d/%m/%Y",localtime($epoch));
    return $datestr;            	                 
}

1;

sub readData() {
	my $file = shift;
	
	open HF, $file or die "Can't open data file, $file\n";
	
	my $i = 0;
	while (<HF>) {
		#print;
		if (/^#/) {
			next;
		}
		chomp;
		my @a = split ",";
		$data{$a[0]} = $a[1];
		$serDate[$i] = $a[0];

		$i++;
	}
	close HF;
}

sub distribution() {
	my $n = shift;
	my $v = shift;
	
	my $d = $v * exp(-$n * $n / $sigma2) / $D;
	
	return $d;
}