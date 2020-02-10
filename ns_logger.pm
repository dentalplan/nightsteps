package ns_logger{
    use strict;
    use warnings;
#    use Time::Piece qw(datetime);    

    sub new{
        my $class = shift;
        my $this = {
            _loop => shift,
        };
        my $rh_time = shift;
        my $i = 0;
        my $fname = "/home/pi/nsdata/log/log$rh_time->[5]-$rh_time->[4]-$rh_time->[3]__$rh_time->[2]-$rh_time->[1]" . (sprintf("%05d",$i)) . ".txt";
        while (-f $fname) {
            $fname = "/home/pi/nsdata/log/log" . (sprintf("%05d",++$i)) . ".txt";
        }
        $this->{_logfile} = $fname;
        open LOG, ">>$this->{_logfile}" or die $!;
#        print LOG "logic: $this->{_loop}->{_logic}\n";
        print LOG '"time","gpstime","lat","lon","compass","daterange_state","daterange_upper","daterange_lower, "logicsound", "sniffversion", "sniffvalue"' . "\n";
        close LOG;
        bless $this, $class;
        return $this; 
    }

    sub logData{
        my $this = shift;
        print "logging data\n";
        my $rhGPS = $this->{_loop}->{_telem}->{_presPosition};
        my $rhDateRange = $this->{_loop}->{_daterange}->{_drlog};
#        my $time = $this->{_loop}->{_t}->datetime;
        my $time = localtime;
        open LOG, ">>$this->{_logfile}" or die $!;
        print LOG "$time,";
        print LOG "$rhGPS->{time},$rhGPS->{lat},$rhGPS->{lon},$rhGPS->{course},";
        print LOG "$rhDateRange->{state},$rhDateRange->{tr},$rhDateRange->{br},";
        print LOG "$this->{_loop}->{_logic}, $this->{_loop}->{_version}, $this->{_loop}->{_val}";
        print LOG "\n";
        close LOG;
    }

}1;
