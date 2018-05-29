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
        bless $this, $class;
        $this->setupReading;
        return $this;
    }

    sub setupReading{
        my $this = shift;
#        system "touch $this->{_datapath}$this->{_channel}.$this->{_mode}";
    }

    sub readValue{
        my $this = shift;
        my $out;
        switch ($this->{_mode}){
            case 'a' {$out = $this->readAnalogue($this->{_channel});}
            case 'd' {$out = $this->readDigital;}
#            case 'c' {$out = $this->readCompass;}
        }
        return $out;
    }

	sub readAllOfMyMode{
        my $this = shift;
        my @val;
        for (my $i=0; $i<8; $i++){
            my $read = $this->readAnalogue($i);
            push @val, $read;
        }
        return \@val;
	}

    sub readAnalogue{
        my ($this, $channel) = @_;
        open SENSOUT, "<$this->{_datapath}$this->{_channel}.$this->{_mode}" or die $!;
        my @sens = <SENSOUT>;
        my $size = @sens;
        my $out = -1;
        for(my $i=$size-1; $i>0 && $out == -1; $i--){
            chomp $sens[$i];
            if ($sens[$i] =~ m/(\d\d\d\d)/){
                $out = $1;
			}
        }   
        return $out;
    }

    sub readDigital{
        print "readDigital sub not yet written!!\n\n";
    }
}
1;
