package ns_audinterface{
#the audio interface layer translates data structures into audio parameters;
    use strict;
    use warnings;
    use ns_chuckout;

    sub new {
        my $class = shift;
        my $this  = {
            _mode => shift,
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
        my $rah_so;
        my $yeardiff = $this->{_maxyear} - $this->{_minyear};
        foreach my $rh_do (@{$rah_do}){
            my $rh_so = {};
            $rh_so->{panning} = $rh_do->{pos};
            $rh_so->{startime} = $rh_do->{dist} / $this->{_maxdist};
            $rh_so->{freq} = ($rh_do->{price} - $pricetune) / $this->{_pricediv};
            $rh_so->{gain} = (($rh_do->{year} - $this->{_minyear})+1) / ($yeardiff + 1); #added +1 to prevent dividing zero 
            if ($rh_do->{hasSAON} == 1){
                $rh_so->{dur} = 50;
            }else{
                $rh_so->{dur} = 50;
            }
            push @{$rah_so}, $rh_so;
        }
        my $ck = ns_chuckout->new;
        $ck->basicOut($rah_so);
    }

    sub chuckWaitOnGPS{
        my $this = shift;
        my $ck = ns_chuckout->new;
        $ck->waitTone;
    }


}
1;


