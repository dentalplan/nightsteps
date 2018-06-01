package ns_logger{
    use strict;
    use warnings;
    use ns_telemetry;
    use ns_gpio;
#    use Time::Piece qw(datetime);    

    sub new{
        my $class = shift;
        my $this = {
            _loop => shift,
            _sensAnalogue => ns_gpio->new('a',0),
        };
        my $i = 0;
        my $fname = "/home/pi/nsdata/log/log" . (sprintf("%05d",$i)) . ".txt";
        while (-f $fname) {
            $fname = "/home/pi/nsdata/log/log" . (sprintf("%05d",++$i)) . ".txt";
        }
        $this->{_logfile} = $fname;
        open LOG, ">>$this->{_logfile}" or die $!;
        print LOG '"time","gpstime","lat","lon","compass","a0","a1","a2","a3","a4","a5","a6","a7",' . "\n";
        close LOG;
        bless $this, $class;
        return $this; 
    }

    sub logSensorData{
        my $this = shift;
        my $rhGPS = $this->{_loop}->{_telem}->readGPS;
#        my $time = $this->{_loop}->{_t}->datetime;
        my $time = localtime;
        my $raSensor = $this->{_sensAnalogue}->readAllAnalogue;
        open LOG, ">>$this->{_logfile}" or die $!;
        print LOG "$time,";
        if ($rhGPS->{success} == 1){
            print LOG "$rhGPS->{time},$rhGPS->{lat},$rhGPS->{lon},$rhGPS->{course},";
        }else{
            print LOG ",,,,";
        }
        foreach my $s (@{$raSensor}){
            print LOG "$s,";
#            print "putting $s in record\n";
        }
        print LOG "\n";
        close LOG;
    }

}1;
