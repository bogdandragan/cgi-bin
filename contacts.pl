#!/usr/bin/perl
use strict;
use CGI; 
use CGI::Carp qw(warningsToBrowser fatalsToBrowser); 
use DBI;
use JSON;
my $q = new CGI;
print $q->header();

sub getDB{
	my $host = "localhost";
	my $user = "root";
	my $pass = "123";
	my $db = "test";
	
	return DBI->connect("DBI:mysql:database=$db;host=$host", $user, $pass, {RaiseError => 1});
}
my $dbh = getDB();

my $json = $q->param('POSTDATA');

my $request;
if($json){
my $json_obj = new JSON;
$request = $json_obj->decode($json);
}


if($request->{action} eq "create"){
	#print $request->{firstname}." ".$request->{lastname}." ".$request->{tel};
	my $sth = $dbh->prepare('INSERT INTO contacts(FirstName,LastName,Tel) VALUES (?,?,?)');
	$sth->execute($request->{firstname}, $request->{lastname}, $request->{tel});
	die;
}
elsif($request->{action} eq 'update'){
	my $sth = $dbh->prepare('UPDATE contacts SET FirstName = ?, LastName = ?, Tel = ? WHERE id = ?');
	$sth->execute($request->{firstname}, $request->{lastname}, $request->{tel}, $request->{id});
	#print "update";
	die;
}
elsif($request->{action} eq 'remove'){
	my $sth = $dbh->prepare('DELETE FROM contacts WHERE id = ?'
	$sth->execute($request->{id});
	die;
}

my $res = $dbh->prepare("SELECT id, FirstName, LastName, Tel FROM contacts");
$res->execute;

my $out;
while(my $next = $res->fetchrow_hashref()){
	if($out ne ""){
		$out .= ',';
	}
	$out .= '{"id":"'.$next->{'id'}.'",'.
			'"firstname":"'.$next->{'FirstName'}.'",'.
			'"lastname":"'.$next->{'LastName'}.'",'.
			'"tel":"'.$next->{'Tel'}.'"}';
}

$dbh->disconnect();

print '{"records":['.$out.']}';

