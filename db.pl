#!/usr/bin/perl
use strict;
use MongoDB;
use CGI;

my $q = new CGI;
print $q->header();

sub initDB {
	my $dbhost = 'localhost';
	my $dbname = 'test';

	#Connect to test database
	my $m = MongoDB::Connection->new;
	my $db = $m->get_database($dbname);
	return $db;
}

sub getUsersCollection{
	my $db = initDB();
	my $collection = $db->get_collection("users");

	return $collection;
}

#my $collection = getUsersCollection();

#my $cursor = $collection->find({});
	
#	while(my $row = $cursor->next){
#		print $row->{"email"}."\n";
#	}
