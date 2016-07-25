#!/usr/bin/perl
# Every minute, get current temperature using 1wire temperature sensor (DS18B20)
# and record in RRD database. On every fifth minute, update the RRD graphs
use strict;
use warnings;
use RRD::Simple;

package main;

my $sensor = '/sys/bus/w1/devices/28-0000059d87ad/w1_slave';
my $rrdFile = './temps.rrd';
#my $rrd = RRD::Simple->new( file => $rrdfile );
my $average;
my $min;
my $max;
my $last;

my $rrd = RRD::Simple->new( file => $rrdFile );

if (! -e $rrdFile) {
  $rrd->create(
    temp => "GAUGE"
  );
}

while ( 1 ) {
  my $time = 0 ;
  while ( $time < 360 ) {
    open FILE, $sensor or die "Couldn't access 1wire device $sensor";
    my @sensFile = <FILE>;
    $sensFile[1] =~ m/t\=(\d{2})(\d{3})/;
    my $temp = "$1.$2";
    print "$temp degrees C \n";
    $rrd->update(
      temp => $temp
    );
    close FILE;
    sleep 60;
    $time+=60
  }


  my %rtn = $rrd->graph(
    destination => "./www/png",
    title => "Garage Temperature",
    vertical_label => "degrees Celsius",
    interlaced => ""
  );
  printf("Created %s\n",join(", ",map { $rtn{$_}->[0] } keys %rtn));

  sleep 60;
}
