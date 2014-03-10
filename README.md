https://github.com/idontwatchtv/replication-check

Overview:

This is a script intended to be run on each MySQL slave to provide HTTP checks
to an HAProxy load balancer. This checks to ensure that the slave is connected
to the master, the slave threads are running and that the slave isn't too far
behind the master by checking Seconds_Behind_Master. A warning on setting this
too low, if you have a lot of writes come in to the master that are then sent
to the slave, Seconds_Behind_Master can jump to a large number, taking your
slave out of the listening pool.


Instructions:

The Perl modules you will need are AnyEvent::HTTPD and DBD::MySQL, you can
usually install these from packages based on your operating system or else
you can install them via cpan or one of the other various ways. On Debian
wheezy, they can be installed by running:

$ sudo apt-get install libanyevent-httpd-perl libdbd-mysql-perl

You will need a user that is capable of running the SHOW SLAVE STATUS command,
which requires PROCESS and either REPLICATION CLIENT or SUPER. I highly
suggest you use REPLICATION CLIENT rather than SUPER for security reasons. To
install this user run the following commands as root on mysql:

mysql> CREATE USER 'health_chk'@'localhost' IDENTIFIED BY 'password';

mysql> GRANT PROCESS, REPLICATION CLIENT ON *.* to 'health_chk'@'localhost';

mysql> CREATE DATABASE dummy;

mysql> GRANT SELECT on dummy.* TO 'health_chk'@'localhost';


Usage:

HAProxy should be relaying a TCP connection with an HTTP health check to the
listening host on the listening address set at the top of replication-check.pl


Contact:

justin@idontwatch.tv
