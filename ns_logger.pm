package ns_logger{
    use strict;
    use warnings;
    use ns_telemetry;
    use ns_gpio;

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
        print LOG '"time","gpstime","lon","lat","compass","a0","a1","a2","a3","a4","a5","a6","a7",' . "\n";
        close LOG;
        bless $this, $class;
        return $this; 
    }

    sub logSensorData{
        my $this = shift;
        my $rhGPS = $this->{_loop}->{_telem}->readGPS;
        my $compass = $this->{_loop}->{_telem}->compass;
        my $time = $this->{_loop}->{_t}->datetime;
        my $raSensor = $this->{_sensAnalogue}->readAllOfMyMode;
        open LOG, ">>$this->{_logfile}" or die $!;
        print LOG "$time,";
        if ($rhGPS->{success} == 1){
            print LOG "$rhGPS->{time},$rhGPS->{lon},$rhGPS->{lat},";
        }else{
            print LOG ",,,";
        }
        print LOG "$compass,";
        foreach my $s (@{$raSensor}){
            print LOG "$s,"; 
        }
        print LOG "\n";
        close LOG;
    }

}1;
