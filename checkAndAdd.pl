#!/usr/bin/perl -w
#
use strict;
use Getopt::Std;

use vars qw($opt_i $opt_d $opt_n);
getopts('d:i:n') or die "Usage: $0 -d sqlite.db -i inputfile -n (dryrun)\n";

($opt_d) or die "Usage: $0 -d sqlite.db -i inputfile -n (dryrun)\n";
($opt_i) or die "Usage: $0 -d sqlite.db -i inputfile -n (dryrun)\n";

(-e "$opt_d") or die "$0 : cant find database file $opt_d\n";
(-e "$opt_i") or die "$0 : cant find input file $opt_i\n";

open(FIN,"$opt_i") or die "$0 : cant open input file $opt_i\n";
while(<FIN>) {
	chomp;
	my $path = $_;
	if (! -e "$path") { print STDERR "$0 : candidate file \"$path\" doesnt exist\n"; }
	else {
		# hash the file
		my $ret = `shasum "$path"`;
		$ret = substr($ret,0,40);
		if ((length($ret) == 40) && ($ret =~ /[0-9a-f]{40}/)) {
			# hash is ok
			my $look = `sqlite3 MyMusic.db "select sha1 from storage where sha1 = \\\"$ret\\\" limit 1"`;
			chomp $look;
			if (length($look) > 33) { print "$0 : already have a copy of \"$path\" with sha1 $look\n"; }
			else {
				# add to database if not a dry run
				if ($opt_n) { print "DRYRUN--would add \"$path\" $ret\n"; }
				else {
					# add it to the database
					print STDERR "sqlite3 MyMusic.db \"insert into storage (sha1,location) values (\"$ret\",\"$path\");\"\n";
					my $add = `sqlite3 MyMusic.db "insert into storage (sha1,location) values (\\\"$ret\\\",\\\"$path\\\");"`;
				}
			}
		}
		else {
			print STDERR "$0 : something wrong with hashing - $ret\n";
		}
	}
}
close(FIN);



exit;


