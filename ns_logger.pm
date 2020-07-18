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
        my $rht = {year=>$rh_time->[5]+1900, month=>$rh_time->[4]+1, day=>$rh_time->[3], hour=>$rh_time->[2], min=>$rh_time->[1]};
        my $ts = sprintf '%04d-%02d-%02d-%02d%02d', $rht->{year}, $rht->{month}, $rht->{day}, $rht->{hour}, $rht->{min};
        my $fname = "/home/pi/nsdata/log/log$ts-" . (sprintf("%03d",$i)) . ".txt";
        while (-f $fname) {
            $fname = "/home/pi/nsdata/log/log$ts-" . (sprintf("%03d",++$i)) . ".txt";
        }
        $this->{_logfile} = $fname;
        open LOG, ">>$this->{_logfile}" or die $!;
#        print LOG "logic: $this->{_loop}->{_logic}\n";
        print LOG '"time","gpstime","lat","lon","compass","daterange_state","daterange_upper","daterange_lower","logicsound","sniffversion","sniffvalue","viewcount","datacount","gpio-a-all.py","compass.py","sig.py","dig.py"' . "\n";
        close LOG;
        bless $this, $class;
        return $this; 
    }

    sub logData{
        my $this = shift;
        print "logging data to $this->{_logfile}\n";
        my $rhGPS = $this->{_loop}->{_telem}->{_presPosition};
        my $rhDateRange = $this->{_loop}->{_daterange}->{_drlog};
#        my $time = $this->{_loop}->{_t}->datetime;
        my %daemon = ( "gpio-a-all.py"=>0,
				                  "compass.py"=>0,
                          "sig.py"=>0,
                          "dig.py"=>0);
        my @nsrun = `ps aux | grep nightsteps`;
        my @keys = keys %daemon;
        foreach my $l (@nsrun){
            foreach my $k(@keys){
           # print $l;
                if ($l =~ m/$k/){
                    $daemon{$k} = 1;
                }
            }
        }
        my $time = localtime;
        open (LOG, ">>$this->{_logfile}") or die $!;
        print LOG "$time,";
        print LOG "$rhGPS->{time},$rhGPS->{lat},$rhGPS->{lon},$rhGPS->{course},";
        print LOG "$rhDateRange->{state},$rhDateRange->{tr},$rhDateRange->{br},";
#        print LOG "$this->{_loop}->{_logic},$this->{_loop}->{_version},$this->{_loop}->{_val},";
        print LOG "$this->{_loop}->{_logic},$this->{_loop}->{_option},,";
        if ($this->{_loop}->{_lastdataset}->{viewcount}) {
          print LOG "$this->{_loop}->{_lastdataset}->{viewcount},$this->{_loop}->{_lastdataset}->{datacount},";
        }else{
          print LOG '"n/a","n/a"';
        }
        print LOG "$daemon{'gpio-a-all.py'},$daemon{'compass.py'},$daemon{'sig.py'},$daemon{'dig.py'}";
        print LOG "\n";
        close (LOG) or die "Couldn't close file";
    }

}1;
