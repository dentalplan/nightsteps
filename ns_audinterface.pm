package ns_audinterface{
#the audio interface layer translates data structures into audio parameters;
    use strict;
    use warnings;
    use ns_testtools;
    use ns_chuckout;

    sub new {
        my $class = shift;
        my $this  = {
            _mode => shift,
            _testtools => ns_testtools->new,
            _gpoutpath => '/home/pi/nsdata/gpio/'
        };
        bless $this, $class;
        return $this;
    }

    sub espeakWaitOnGPS{
        `espeak "waiting on GPS" --stdout | aplay -D default:Device`;
    }

    sub LRDBespeak1{
        my ($this, $rh_pl) = @_;
        my $address = $rh_pl->{"SAON"} . " " . $rh_pl->{"PAON"}  . " " . $rh_pl->{"Street"};
        my $price = $rh_pl->{"Price"};
        my $year = substr $rh_pl->{"DateOfTransfer"}, 0, 4;
        `espeak "$address sold in $year for $price pounds" --stdout | aplay -D default:Device`;
    }

    sub LRDBchuckBasic1{
        my $this = shift;
        my $rah_do = shift; # pos, dist, price, year, hasSAON
        my $pricetune = shift; # minyear, maxyear, pricetune, pricediv, maxdist
        my @rah_so;
        my $yeardiff = $this->{_maxyear} - $this->{_minyear};
        print "\nAUD OBJECT ATTRIBUTES:\n";
        $this->{_testtools}->printRefHashValues($this);
        foreach my $rh_do (@{$rah_do}){
            print "\nDATA OBJECT VALS:\n";
            $this->{_testtools}->printRefHashValues($rh_do);
            my $hetfreq = ($rh_do->{price} - $pricetune) / $this->{_pricediv};
            my $outfreq = sqrt($hetfreq*$hetfreq);
            if ($outfreq > 10000){
                $outfreq = 0; #lowpass......
            }
            my $rh_so = {
                        panning => $rh_do->{pos},
                        starttime => $rh_do->{dist} / $this->{_maxdist},
                        freq => $outfreq, 
                        gain => (($rh_do->{year} - $this->{_minyear})+1) / ($yeardiff + 1), #added +1 to prevent dividing zero 
            };
            if ($rh_do->{hasSAON} == 1){
                $rh_so->{dur} = 60;
            }else{
                $rh_so->{dur} = 50;
            }
            print "\nSONIC OBJECT VALS:\n";
            $this->{_testtools}->printRefHashValues($rh_so);
            push @rah_so, $rh_so;
        }
        my $ck = ns_chuckout->new;
        $ck->basicOut(\@rah_so);
    }

    sub LDDBpercussBasic1{
        my $this = shift;
        my $out = 1;
        my $file = $this->{_gpoutpath} . "dig$out.o";
        my $rah_do = shift; # pos, dist, price, year, hasSAON
        my @clicks = ();
        foreach my $rh_do (@{$rah_do}){
            my $click = int(($rh_do->{dist} / $this->{_maxdist}) * 40);
            push @clicks, $click;
        }
        $this->digClicks($file, \@clicks);
    }

    sub chuckWaitOnGPS{
        my $this = shift;
        my $ck = ns_chuckout->new;
        $ck->waitTone;
    }

    sub physSendInstructions{
        my ($this, $file, $ra_instr) = @_;
        open (FO, ">", $file);
        foreach my $l (@{$ra_instr}){
            print FO "$l\n";
        }
        close FO;
    }

    sub digClicks{
        my ($this, $file, $ra_clicks) = @_; #strength, 
        my $mode = 't';
        my $size = @{$ra_clicks};
        my @lines = ($mode);
        for (my $i=0; $i<$size; $i++){
            my $h = 15 + $ra_clicks->[$i];
            my $l = 55 - $ra_clicks->[$i];
            my $rep = 3;
            for (my $r=0; $r<$rep;$r++){
                push @lines, "h$h";
                push @lines, "l$l";
            }
            push @lines, "l400";
        }
        push @lines, "l500";
        $this->physSendInstructions($file, \@lines);
    }

    sub digBeat{
        my ($this, $out, $mode, $rep, $style) = @_;
        my $file = $this->{_gpoutpath} . "dig$out.o";
        my @instr = ($mode);
        my ($l, $h, $r);
        if ($style eq "a"){
            $l = "l30";
            $h = "h40";
            $r = 3;
        }elsif ($style eq "b"){
            $l = "l30";
            $h = "h60";
            $r = 2;
        }
        for (my $i=0; $i < $rep; $i++){
            push @instr, "l150"; 
            for (my $k=0; $k < $r; $k++){
            push @instr, $h;
            push @instr, $l;
            }
        }
        push @instr, "l900";
        $this->physSendInstructions($file, \@instr);
    }

    sub digWaitOnGPS{
         
    }

}
1;


