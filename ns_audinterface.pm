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

    sub PPDckBasic1{
        my $this = shift;
        my $rah_do = shift; # pos, dist, price, year, hasSAON
        my $rh_param = shift; # minyear, maxyear, pricetune, pricediv, maxdist
        my $rah_so;
        my $yeardiff = $rh_param->{maxyear} - $rh_param->{minyear};
        foreach my $rh_do (@{$rah_do}){
            my $rh_so = {};
            $rh_so->{panning} = $rh_do->{pos};
            $rh_so->{startime} = $rh_do->{dist} / $rh_param->{maxdist};
            $rh_so->{freq} = ($rh_do->{price} - $rh_param->{pricetune}) / $rh_param->{pricediv};
            $rh_so->{gain} = (($rh_do->{year} - $rh_param->{minyear})+1) / ($yeardiff + 1); #added +1 to prevent dividing zero 
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


}
1;


