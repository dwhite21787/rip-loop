#!/usr/bin/perl -w

use strict;

use vars qw( $gvfsHome $cddaHost $ls @fileList $idFile $currentID $stop $hashFile %trackSig $storageHome );

$gvfsHome = '/run/user/1000/gvfs';
$cddaHost = 'cdda:host=sr0';
$idFile = 'lastID.txt';
$hashFile = 'trackHashes.txt';
$storageHome = './ripped';

if (! -d "$storageHome") { print `mkdir -vp "$storageHome"`; }

if (! -e "$hashFile") { 
	print STDERR "$0 : no track hashes to load.\n";
}
else {
	# format : MD5 tab filename
	open(FIN,"<", $hashFile) or die "$0 : cannot load track hashes from $hashFile, dying\n";
	while(<FIN>) {
		chomp;
		my @p = split(/\t/,$_,2);
		$trackSig{$p[0]} = $p[1];
	}
	close(FIN);
}
print STDERR "$0 : ", scalar(keys(%trackSig)) , " track hashes loaded.\n";

if (! -e "$idFile") { 
	open(FOUT,">",$idFile) or die "$0 : cannot initialize ID file $idFile, dying\n";
	print FOUT "0";
	close(FOUT);
}
open(FIN,"<",$idFile) or die "$0 : cannot open ID file $idFile, dying\n";
$currentID = <FIN>;
chomp $currentID;
close(FIN);

$stop = 'n';

while(uc(substr($stop,0,4)) ne 'QUIT') {

    print "\nType QUIT to stop, or a note about this CD (artist TAB album TAB notes) \n\t:";
    $stop = <STDIN>;
    if (uc(substr($stop,0,4)) ne 'QUIT') {
	    print `mkdir -vp "$storageHome/$currentID" `;
            open(FOUT, ">>", "$storageHome/$currentID/notes.txt");
	    print FOUT "$stop\n";
	    close(FOUT);
    
        if (! -e "$gvfsHome") { die "$0 : cant find gvfs home dir $gvfsHome\n"; }
        if (! -e "$gvfsHome/$cddaHost") { print "Insert CD and press Enter..."; my $press = <STDIN> ; }
        if (! -e "$gvfsHome/$cddaHost") { die "$0 : cant find gvfs cdda dir $gvfsHome/$cddaHost\n"; }
        $ls = `ls "$gvfsHome/$cddaHost/"`;
        chomp $ls;
        if (length($ls) < 1) { die "$0 : seem to be no files in $gvfsHome/$cddaHost\n"; }

        @fileList = split(/\n/,$ls);
        print STDERR "$0 : ", scalar(@fileList) , " files found.\n";

        my $work = 0;
        for my $f (@fileList) {
	    # my $md5 = `md5sum "$gvfsHome/$cddaHost/$f"`;
	    my $md5 = `dd if="$gvfsHome/$cddaHost/$f" bs=32k count=1 | md5sum `;
	    $md5 = substr($md5,0,32);
	    if (defined($trackSig{$md5}) && ($trackSig{$md5} eq $f)) {
		    print "\trepeated track $f\n";
	    }
	    else {
		    $work=1;
		    print `mkdir -vp "$storageHome/$currentID" && cp -v "$gvfsHome/$cddaHost/$f" "$storageHome/$currentID/" && chmod -v a-w "$storageHome/$currentID/$f"`;
		    if (-e "$storageHome/$currentID/$f") {
			    $trackSig{$md5} = $f;
	                    open(FOUT,">>", $hashFile) or die "$0 : cannot save track hash to $hashFile, dying\n";
			    print FOUT "$md5\t$f\n";
			    close(FOUT);
		    }
		    else {
			    print STDERR "$0 : track $f FAILED to copy\n";
		    }
	    }
        }
        print "Ejecting CD ... ";
        print `eject`;

    # if work happened, $currentID++ 
        if ($work) { $currentID++; 
            open(FOUT,">",$idFile) or die "$0 : cannot save ID $currentID to ID file $idFile, dying\n";
            print FOUT $currentID;
            close(FOUT);
        }
    } # did not QUIT
} # while $stop

open(FOUT,">",$idFile) or die "$0 : cannot save ID $currentID to ID file $idFile, dying\n";
print FOUT $currentID;
close(FOUT);

print "Current CD ID is at $currentID - done!\n";
exit;

__END__

/run/user/1000/gvfs/cdda\:host\=sr0/

