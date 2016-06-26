#!/usr/bin/perl
use strict;
use warnings;
use HTTP::Request;
use LWP::Simple;

package main;
die "Must run as root\n" unless $> == 0;

use constant ZONE => 'rpz.bikeshed.internal';
use constant RPZ => "/var/lib/bind/db.".ZONE; # BIND response policy zone (RPZ)
use constant TMP => '/tmp/rpz.tmp';
use constant CNAME => 'brox.bikeshed.internal.';

open my $in,  '<', RPZ or die "Can't read file: $!";
open my $out, '>', TMP or die "Can't write new file: $!";

my @in_rpz = ();
while(<$in>) {   
  $_ =~ s/^(\s+)(\d+)(\s+;\s+serial)/$1.($2+1).$3/e; # increment serial number
  print $out $_;
  next if (($_ =~ m/^\$/) || ($_ =~ m/^\@/) || ($_ =~ m/^\s/) || ($_ =~
m/^#/));
  push (@in_rpz, $_);
}   

my @content = split /\n/, get
'http://pgl.yoyo.org/adservers/serverlist.php?hostformat=one-line&showintro=0&startdate[day]=&startdate[month]=&startdate[year]=';
die "Couldn't get adserver list" unless @content;

# Parse response data
foreach my $line (@content) {
  next unless ($line =~ m/^\w+\.\w+(\.\w)*\,/);
  ($main::dns = $line) =~ s/<\/pre>//;
}
die "Failed to parse adserver list" unless $main::dns;

# Add record for each adServer to RPZ, if not already listed
DN:
foreach my $dn (split /,/, $main::dns) {
  foreach (@in_rpz) {
    next DN if ($_ =~ m/^$dn/);
  }
  printf $out "%-46sCNAME   %s\n", $dn, CNAME;
  $main::rpzUpdated = 1;
}

close $out;

unless ($main::rpzUpdated) {
  unlink TMP;
  exit 0;
}

rename TMP, RPZ or die "Failed to write rpz file " . RPZ;
system("/usr/sbin/rndc", "reload", ZONE);

exit 0;
