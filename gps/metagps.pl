use strict;
use warnings;
use Time::Piece;

for(;;){
	system("perl /home/pi/nightsteps/gps/gps.pl>/home/pi/nsdata/gpsout.txt");
  my @time = localtime(time);
  my $rh_time = shift;
  my $i = 0;
  my $rht = {year=>$rh_time->[5]+1900, month=>$rh_time->[4]+1, day=>$rh_time->[3], hour=>$rh_time->[2], min=>$rh_time->[1]};
  my $ts = "$rht->{year}-$rht->{month}-$rht->{day}_$rht->{hour}-$rht->{min}";
  my $fname = "/home/pi/nsdata/gpslog/gps_$ts-" . (sprintf("%03d",$i)) . ".txt";
  while (-f $fname) {
      $fname = "/home/pi/nsdata/gpslog/gps_$ts-" . (sprintf("%03d",++$i)) . ".txt";
  }
  system("cp /home/pi/nsdata/gpsout.txt $fname");
	print "GPS sequenceEnded -- restarting....\n";
	sleep(1);
#	print "GPS module disabled";
#	sleep(30);
}
