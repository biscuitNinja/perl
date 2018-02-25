#!/usr/bin/perl -w
use strict;
use warnings;
use Net::Telnet ();

my $state = shift @ARGV;
my $outlet = shift @ARGV;

my $telnet = new Net::Telnet(
    Timeout                  => 60,
    Errmode                  => 'return',
    Prompt                   => '/.*>/',
    Output_record_separator  => '',
    );
$telnet->open(Host => "BS-PDU-1");

# login 
$telnet->waitfor('/User Name : /');
$telnet->print("<$$PDU_PASSWORD$$>\n");
$telnet->waitfor('/Password  : /');
$telnet->print("<$$PDU_PASSWORD$$> -c\n");
$telnet->waitfor('/APC\>');
$telnet->print($state . " " . $outlet . "\n");
$telnet->close();
exit(0);
