package ns_gpio{
    use strict;
    use warnings;
    use Switch;

    sub new{
        my $class = shift;
        my $this = {
                    _mode => shift,
                    _channel => shift,
                    _datapath => '/home/pi/nsdata/gpio/',
                    };
        if ($this->{_mode} eq 'a'){
            $this->{_presReadings} = {'','','','','','','',''};
        }
        bless $this, $class;
        $this->setupReading;
        return $this;
    }

    sub setupReading{
        my $this = shift;
#        system "touch $this->{_datapath}$this->{_channel}.$this->{_mode}";
    }

    sub writeInstructions{
        my $this = shift;
        my $ra_instr = shift;
        my $prefix = "";
        if ($this->{_mode} eq 'digOut'){
            $prefix = "dig";
        }elsif ($this->{_mode} eq 'pmwOut'){
            $prefix = "pwm";
        }
        my $file = $this->{_datapath} . $prefix . $this->{_channel} . ".o";
        open (FO, ">", $file);
        foreach my $l (@{$ra_instr}){
            print FO "$l\n";
        }
        close FO;
    }

    sub readValue{
        my $this = shift;
        my $out;
        switch ($this->{_mode}){
            case 'a' {$out = $this->readAnalogue($this->{_channel});}
            case 'd' {$out = $this->readDigital;}
            case 'c' {$out = $this->readCompass;}
            case 'digOut' {print "Not readable";}
        }
        return $out;
    }

    sub readAllAnalogue{
        my ($this) = @_;
        open SENSOUT, "<$this->{_datapath}a.a" or die $!;
        my @sens = <SENSOUT>;
        my $size = @sens;
        my @out;
        for(my $i=$size-1; $i>0 && @out < 1; $i--){
            chomp $sens[$i];
            if ($sens[$i] =~ m/(\d\d\d\d)-(\d\d\d\d)-(\d\d\d\d)-(\d\d\d\d)-(\d\d\d\d)-(\d\d\d\d)-(\d\d\d\d)-(\d\d\d\d)-/){
                push @out, $1;
                push @out, $2;
                push @out, $3;
                push @out, $4;
                push @out, $5;
                push @out, $6;
                push @out, $7;
                push @out, $8;
			}
        }
        $this->{_presReadings} = \@out;
        return \@out;
    }


    sub readAnalogue{
        my ($this, $channel) = @_;
        my $rh_out = $this->readAllAnalogue;
        my $out = $rh_out->[$channel];
#        my @sens = <SENSOUT>;
#        my $size = @sens;
#        my $out = -1;
#        for(my $i=$size-1; $i>0 && $out == -1; $i--){
#            chomp $sens[$i];
#            if ($sens[$i] =~ m/(\d\d\d\d)/){
#                $out = $1;
#			}
#        }   
#        print "sensor $channel: $out\n";
        return $out;
    }

    sub readCompass{
        my $this = shift;
        open SENSOUT, "<$this->{_datapath}0.$this->{_mode}" or die $!;
        my @sens = <SENSOUT>;
        my $size = @sens;
        my $out = -1;
        for(my $i=$size-1; $i>0 && $out == -1; $i--){
            chomp $sens[$i];
            if ($sens[$i] =~ m/([0-9]+\.[0-9]+)/){
                $out = $1;
			}
        }   
#        print "compass:  $out\n";
        return $out;

    }

    sub readDigital{
        print "readDigital sub not yet written!!\n\n";
    }
}
1;
