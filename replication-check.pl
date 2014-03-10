#!/usr/bin/perl
##
# https://github.com/idontwatchtv/replication-check
# by Justin <justin@idontwatch.tv>
#
# BSD license
# 

use strict;
use warnings;
use AnyEvent::HTTPD;
use DBD::mysql;
#use Data::Dumper;

# Slave connection information
my $dbs_host = '10.0.0.30';
my $dbs_user = 'host_chk';
my $dbs_pass = 'password';
my $dbs_port = '3306';
my $dbs_database = 'dummy';

# httpd listening port for health checks from HAProxy
my $listen_host = '0.0.0.0';
my $listen_port = '4001';

# other variables
my $max_seconds_behind = 30; # Maximum seconds behind the master before the slave responds with 503
my $request_timeout = 10; # http timeout for request
my $dbh;

#===============================================================================
# Start http server
my $httpd = AnyEvent::HTTPD->new (host => $listen_host, port => $listen_port, request_timeout => $request_timeout);

$httpd->reg_cb (
	'/slavecheck' => sub {
		my ($httpd, $req) = @_;
		# connect to our localhost/slave
		unless ($dbh = DBI->connect("dbi:mysql:database=$dbs_database;host=$dbs_host;port=$dbs_port", $dbs_user, $dbs_pass, { PrintError => 0 })){
			$req->respond([503, 'SERVICE UNAVAILABLE', {'Content-Type' => 'text/html'}, '<h1>503 - Cannot connect to MySQL slave</h1>']);
			return;
		}

		# Run our query. SHOW SLAVE STATUS requires PROCESS and REPLICATION CLIENT 
		my $sth = $dbh->prepare('SHOW SLAVE STATUS');
		$sth->execute();
		my $slave_result = $sth->fetchrow_hashref();

		# Check is SQL thread is running, if not error
		if ($slave_result->{Slave_SQL_Running} ne 'Yes') {
			$req->respond([503, 'SERVICE UNAVAILABLE', {'Content-Type' => 'text/html'},
			"<h1>503 - Slave SQL not running, did you run STOP SLAVE; ?</h1>"]);
		}

		# http://dev.mysql.com/doc/refman/5.5/en/start-slave.html
		# Slave_IO_Running=YES only if the I/O thread is running AND CONNECTED
		if ($slave_result->{Slave_IO_Running} ne 'Yes') {
			my $io_error = ($slave_result->{Slave_IO_Running} eq 'Connecting') ? 'Establishing a connection to the master!' : ' Did you run STOP SLAVE; ?';
			$req->respond([503, 'SERVICE UNAVAILABLE', {'Content-Type' => 'text/html'}, 
			'<h1>503 - Slave IO not running, ' . $io_error . '</h1>' ]);
		}

		# When Seconds_Behind_Master is undefined that means the slave is not connected to the master
		# might be an unnecessary check
		if (!defined($slave_result->{Seconds_Behind_Master})) {
			$req->respond([503, 'SERVICE UNAVAILABLE', {'Content-Type' => 'text/html'},
			"<h1>503 - Slave is not connected to the master</h1>"]);
		}

		# Check for maximum seconds_behind_slave, may need to average it out some how because of big writes
		if (defined($slave_result->{Seconds_Behind_Master}) && $slave_result->{Seconds_Behind_Master} gt $max_seconds_behind) {
			$req->respond([503, 'SERVICE UNAVAILABLE', { 'Content-Type' => 'text/html' },
			'<h1>503 - Slave is lagging behind the master, currently '. $slave_result->{Seconds_Behind_Master} .' seconds behind</h1>']);
		}

		#print Dumper($slave_result); 
		
		# Everything passed, respond with a 200 - OK
		$req->respond([200, "OK", {'Content-Type' => 'text/html'}, '<h1>200 - Everything is fine</h1>']);

	},

);

$httpd->run;

#### TODO
# check master log file & position, compare it to the slave's?
# add option to allow dirty reads from a slave not connected to the master
