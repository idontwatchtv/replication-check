https://github.com/idontwatchtv/replication-check

Overview:

This is a script intended to be run on each MySQL slave to provide HTTP checks
to an HAProxy load balancer. This checks to ensure that the slave is connected
to the master, the slave threads are running and that the slave isn't too far
behind the master by checking SECONDS_Behind_MASTER.

Instructions:

The perl modules you will need are AnyEvent::HTTPD and DBD::MySQL, you can
usually install these from packages based on your operating system or else
you can install them via cpan or one of the other various ways. On Debian
wheezy, they can be installed by running:

$ sudo apt-get install libanyevent-httpd-perl libdbd-mysql-perl

Contact:

https://github.com/idontwatchtv/replication-check
justin@idontwatch.tv
