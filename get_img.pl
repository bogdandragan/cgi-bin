#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser); 

my $query = new CGI;

my $type = $query->param('type');

my $image;
my $buff;

if($type eq "gif"){
	print "Content-type: image/gif\n\n";
	open (my $fh, "/var/www/test/service/images/1.gif");
	while(read($fh, $buff, 1024)) {
    	$image .= $buff;
	}
	close $fh;
	print $image;	
}
elsif($type eq "png"){
	print "Content-type: image/png\n\n";
	open (my $fh, "/var/www/test/service/images/1.png");
	while(read($fh, $buff, 1024)) {
    	$image .= $buff;
	}
	close $fh;
	print $image;	
} 
elsif($type eq "jpeg"){
	print "Content-type: image/jpeg\n\n";
	open (my $fh, "/var/www/test/service/images/1.jpeg");
	while(read($fh, $buff, 1024)) {
    	$image .= $buff;
	}
	close $fh;
	print $image;	
}
else{
	die "no image type specified";
}



