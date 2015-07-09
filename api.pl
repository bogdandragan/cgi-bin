#!/usr/bin/perl
use strict;
use warnings;
use Switch;
use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser); 
use JSON;
use Data::Dumper;
use DB;
use LWP::Simple;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Encode;
use MIME::Lite;
use Net::SMTP::TLS; 
use MIME::Base64;
#my $domain = "http://46.46.87.154:88/test-task/";
#$domain = "http://localhost/test/";
my $domain = "http://localhost/test/";
require 'db.pl';
my $q = new CGI;
#print $q->header();

my $json = $q->param('POSTDATA');

my $json_obj = new JSON;
my $request = $json_obj->decode($json);

switch ($request->{action}) {
	case "login"{
		login($request->{params});
	}
	case 'register'{
		register($request->{params});
	}
	case 'forgot'{
		forgot($request->{params});
	}
	case 'newPass'{
		newPassword($request->{params});
	}
	case 'checkToken'{
		checkToken($request->{params});
	}
	case 'getUserByToken'{
		getUserByToken($request->{params});
	}
	case 'getUserById'{
		getUserById($request->{params});
	}
	case 'getUsers'{
		getUsers($request->{params});
	}
	case 'updateUser'{
		updateUser($request->{params});
	}
	case 'checkRole'{
		checkRole($request->{params});
	}
	else{
		last;
	}
}

sub login{
	my $params = shift;
	my $collection = getUsersCollection();	
	my $pass = $params->{pass};
	$pass = md5_hex($pass);
	my $user = $collection->find_one({ email => $params->{email}, password => $pass });
	
	if($user){	#Generate AccessToken
		my $accessToken = md5_hex(time().$user->{_id});
		#add timestamp to visits history
		my @visits = $user->{'timestamp'};

		push($user->{timestamp}, time());
		
		$collection->update({ email => $params->{email}}, { '$set' => { accessToken => $accessToken, timestamp => $user->{timestamp}}});
		
		my $tojson = {error => "", data=>{accessToken => $accessToken}};
		print $json_obj->encode($tojson);
	}
	else{
		my $tojson = {error => "incorrect email or password"};
		print $json_obj->encode($tojson);
	}
}

sub register{
	my $params = shift;
	my $collection = getUsersCollection();
	#check if user exists
	my $user = $collection->find_one({email => $params->{email}});

	if($user){
		my $tojson = {error => "Email address already in use"};
		print $json_obj->encode($tojson);
		die;
	}
	#save photo
	my $filename;
	if($params->{photo}){
		$filename = savePhoto($params->photo);	
	}
	else{
		$filename = './images/default.jpg';	
	}	
	$collection->insert( {name => $params->{name}, 
					  lastname => $params->{lastname},
					  email => $params->{email},
					  address => $params->{address},
					  password => md5_hex($params->{password}),
					  photo => $filename,
					  timestamp => '',
					  isAdmin => "false",
					  accessToken => '',
					  passCode => ''} );
					  						  
	#//Generate accessToken
	my $accessToken = md5_hex(time().$user->{_id});
	#//add timestamp to visits history
	#my @visits = (time());
	$collection->update({email => $params->{email}}, { '$set' => { accessToken => $accessToken, timestamp => [time()]}});
	
	my $tojson = {error => "", data=>{accessToken => $accessToken}};
	print $json_obj->encode($tojson);
}

sub forgot{
	my $params = shift;
	my $collection = getUsersCollection();
	#check if user exists
	my $user = $collection->find_one({email => $params->{email}});
	
	if($user){
		#//Generate password reset code
		my $passCode = md5_hex(time().$params->{email});
		#print $passCode;
		$collection->update({email => $params->{email}}, {'$set' => {passCode => $passCode}});
		
		#//send email
		my $mailer = new Net::SMTP::TLS(
    'smtp.gmail.com',
    Hello   =>      'smtp.gmail.com',
    Port    =>      587,
    User    =>      'bogdan@dragan.com.ua',
    Password=>      'bogdan123456');
		
		$mailer->mail('from@domain.com');
		$mailer->to('bogdan@dragan.com.ua');
		$mailer->data;
		$mailer->datasend("From: " . 'from@domain.com' . "\n");
		$mailer->datasend("Subject: ".'Password reset request'."\n");
		$mailer->datasend("To reset your password, please follow this link\n".$domain."new_pass.html#".$passCode);
		$mailer->dataend;
		$mailer->quit;

		my $tojson = {error => ""};
		print $json_obj->encode($tojson);
	}
	else{
		my $tojson = {error => "Email not found"};
		print $json_obj->encode($tojson);
	}
}

sub newPassword{
	my $params = shift;
	my $collection = getUsersCollection();
	my $user = $collection->find_one({passCode => $params->{passCode}});

	if($user){
		my $password = md5_hex($params->{password});
		my $accessToken = md5_hex(time().$user->{_id});
		
		my @visits = $user->{timestamp};
		my $size = @visits;
		
		push($user->{timestamp}, time());
		
		$collection->update({passCode => $params->{passCode}}, { '$set' => { accessToken => $accessToken, password => $password, passCode => "", $user->{timestamp}}});
		
		my $tojson = {error => "", data => {accessToken => $accessToken}};
		print $json_obj->encode($tojson);		
	}
	else{
		my $tojson = {error => "Password reset code is not valid"};
		print $json_obj->encode($tojson);		
	}
}

sub checkToken{
	my $params = shift;
	my $collection = getUsersCollection();
	my $user = $collection->find_one({accessToken => $params->{accessToken}});

	if($user){
		my $tojson = {error => ""};
		print $json_obj->encode($tojson);	
	}
	else{
		my $tojson = {error => "Invalid access token"};
		print $json_obj->encode($tojson);
	}
}

sub getUserByToken{
	my $params = shift;
	my $collection = getUsersCollection();
	my $user = $collection->find_one({accessToken => $params->{accessToken}});
	my $id = $user->{_id};
	if($user){
		my $tojson = {error => "User"};
	    $tojson = {error => "", data => {id => $user->{_id},
											name => $user->{name},
											lastname => $user->{lastname},
											email => $user->{email},
											address => $user->{address},
											photo => $user->{photo},
											timestamp => $user->{timestamp},
											isAdmin => $user->{isAdmin}}};
		
		print $json_obj->allow_blessed->convert_blessed->encode($tojson);
	}
	else{
		my $tojson = {error => "User not found"};
		print $json_obj->encode($tojson);
	}
}

sub getUserById{
	my $params = shift;
	my $collection = getUsersCollection();
	my $user = $collection->find_one({_id => MongoDB::OID->new(value => $params->{id})});

	if($user){
		my $tojson = {error => "", 'data' => {name => $user->{name},
											lastname => $user->{lastname},
											email => $user->{email},
											address => $user->{address},
											photo => $user->{photo},
											timestamp => $user->{timestamp},
											isAdmin => $user->{isAdmin}}};
		print $json_obj->allow_blessed->convert_blessed->encode($tojson);
	}
	else{
		my $tojson = {error => "User not found"};
		print $json_obj->encode($tojson);
	}
}

sub getUsers{
	my $params = shift;
	my $collection = getUsersCollection();
	my $user = $collection->find_one({accessToken => $params->{accessToken}});

	if($user){
		my $users = $collection->find( { accessToken => {'$ne' => $user->{accessToken}}}, { name => 1, lastname => 1, address => 1, email => 1, photo => 1, timestamp => 1 });
		my @arr = $users->all;
		#print @arr;
		my $tojson = {error => "", data => \@arr};
		
		print $json_obj->allow_blessed->convert_blessed->encode($tojson);
		
		#print $json_obj->encode($tojson);
	}
	else{
		my $tojson = {error => "User not found"};
		print $json_obj->encode($tojson);
	}
}

sub savePhoto{
	my $in = shift;
	my @values = split(',', $in);
	
	my @type = split('/',$values[0]);
	@type = split(';',$type[1]);
    my $type = $type[0];
	my $base64 = $values[1];
	#print $type;
	#print $base64;
	my $decoded= MIME::Base64::decode_base64($base64);
	my $filename = './images/'.md5_hex(time()).'.'.$type;
	#chmod(0755, '/var/www/test/sservice/'.$filename) or die "Can't change permissions: $!";	
	
	open(my $fh, '>', '/var/www/test/service/'.$filename) or die $!; 
	binmode $fh;
	print $fh $decoded;
	close($fh); 
	
	return $filename;
}

sub updateUser{
	my $params = shift;
	my $collection = getUsersCollection();
	my $user = $collection->find_one({_id => MongoDB::OID->new(value => $params->{id})});

	if($user){
		my $name = $params->{name};
		my $lastname = $params->{lastname};
		my $address = $params->{address};
		if($params->{email}){
			my $email = $params->{email};
			$collection->update({_id => MongoDB::OID->new(value => $params->{id})}, { '$set' => { email => $email}});
		}
		if($params->{password}){
			my $password = md5_hex($params->{password});
			$collection->update({_id => MongoDB::OID->new(value => $params->{id})}, { '$set' => { password => $password}});	
		}
		if($params->{photo}){
			my $filename = savePhoto($params->{photo});
			#$filename = "filename";
			my $photo = $filename;
			$collection->update({_id => MongoDB::OID->new(value => $params->{id})}, { '$set' => { photo => $photo}});
		}
		
		$collection->update({_id => MongoDB::OID->new(value => $params->{id})}, { '$set' => { name => $name, lastname => $lastname, address => $address}});

		my $tojson = {error => ""};
		print $json_obj->encode($tojson);
	}
	else{
		my $tojson = {error => "User not found"};
		print $json_obj->encode($tojson);
	}
}

sub checkRole{
	my $params = shift;
	my $collection = getUsersCollection();
	my $user = $collection->find_one({accessToken => $params->{accessToken}});

	if($user){
		my $tojson = {error => '', data => {isAdmin => "$user->{isAdmin}"}};
		print $json_obj->encode($tojson);
	}
	else{
		my $tojson = {error => 'User not found'};
		print $json_obj->encode($tojson);
	}
}
