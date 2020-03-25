use strict;
use warnings;

for(;;){
	sleep(4);
	system("perl /home/pi/nightsteps/gps/gps.pl>/home/pi/nsdata/gpsout.txt");
	print "GPS crashed -- restarting....\n";
#	print "GPS module disabled";
#	sleep(30);
}
