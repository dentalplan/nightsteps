package ns_loopit{
    use strict;
    use warnings;
    use ns_dbinterface;
    use ns_telemetry;
    use ns_audinterface;
    use Math::Polygon;
    use Math::Polygon::Calc;
    use Switch;
    use Time::Piece;

    sub new{
        my $class = shift;
        my $rh = shift;
        my $this = {
            _listenshape => $rh->{listenshape},
            _logic => $rh->{logic},
            _maxdist => $rh->{maxdist},
            _telem => ns_telemetry->new,
            _aud => ns_audinterface->new,
            _db => ns_dbinterface->new,
            _t => Time::Piece->new,      
        };
        bless $this, $class;
        $this->loopitSetup;
        return $this;
    }

    sub loopitSetup{
        my $this = shift;
        switch ($this->{_logic}){
            case "LRDBespeak1"{ $this->LRDBespeak1Setup}
        }
    }

    sub iterate{
        my $this = shift;
        switch ($this->{_logic}){
            case "LRDBespeak1" { $this->LRDBespeak1It }
        }
    }

    ##LRDB Block 
    ### espeak 1
    sub LRDBespeak1Setup{
        my $this = shift;
        $this->{_it} = 1996;
        $this->{_yardstick} = $this->{_t}->year;
        $this->{_db}->connectDB('lrdb.sqlite');
    }

    sub LRDBespeak1It{
        my $this = shift;
        if ($this->{_it} > $this->{_yardstick}){ $this->{_it}=1996; }
        my $rh_loc = $this->{_telem}->readGPS;
        if ($rh_loc->{success} == 1){
            print "GPS success!\n";
            my $DLen = $this->{_telem}->getDegreeToMetre($rh_loc);
            my $polyco = $this->{_telem}->prepPolyCo($rh_loc, $this->{_listenshape});
            my $condition = "DateOfTransfer Like \"$this->{_it}%\" AND ";
            my $rah_places = $this->LRDBprepPlaces($rh_loc, $DLen, $condition);
            if ($rah_places){
                foreach my $rh_pl (@{$rah_places}){
                    if ($this->{_telem}->checkPointIsInShape($rh_pl, $polyco) == 1){
                        $this->{_aud}->LRDBespeak1($rh_pl);
                    }
                }
            }
        }elsif($this->{_it}==1996){$this->{_aud}->espeakWaitOnGPS;}
        $this->{_it}++;
    }

    ### chuck 1
    sub LRDBchuck1Setup{
        my $this = shift;
        $this->{_db}->connectDB('lrdb.sqlite');
        $this->{_aud}->{_minyear} = 1996;
        $this->{_aud}->{_maxyear} = Time::Piece->year;
        $this->{_aud}->{_pricediv} = 100;
    }
    
    sub LRDBchuck1It{
        my $this = shift;
        my $rh_loc = $this->{_telem}->readGPS;
        if ($rh_loc->{success} == 1){
            print "GPS success!\n";
            my $DLen = $this->{_telem}->getDegreeToMetre($rh_loc);
            my $polyco = $this->{_telem}->prepPolyCo($rh_loc, $this->{_listenshape});
            my $condition = "";
            my $rah_places = $this->LRDBprepPlaces($rh_loc, $DLen, $condition);
            if ($rah_places){
                my $pricetune = $this->LRDBaveragePrice($rah_places);
                my $rah_do;
                foreach my $rh_pl (@{$rah_places}){
                    if ($this->{_telem}->checkPointIsInShape($rh_pl, $polyco) == 1){
                        
                        my $rh_do = {
                                        pos => 0,
                                        dist => $this->{_telem}->getDistanceInMetres()/$this->{_maxdist},
                                        price => $rh_pl->{Price},
                                        year => int(substr($rh_pl->{DateOfTransfer},0,4)),
                                        SAON => $rh_pl->{SAON},
                        };
                    }
                }
                $this->{_aud}->LRDBchuck1($rah_do, $pricetune);
            }
        }else{
            $this->{_aud}->chuckWaitOnGPS
        }
    }

    ### generic LRDB
    sub LRDBprepPlaces{ 
        my ($this, $rh_loc, $DLen, $condition) = @_;
        my $distmet = 20;
        my $distlon = $distmet/$DLen->{lon};
        my $distlat = $distmet/$DLen->{lat};
        my %lon = (min=>$rh_loc->{lon} - $distlon, max=>$rh_loc->{lon} +$distlon) ;
        my %lat = (min=>$rh_loc->{lat} - $distlat, max=>$rh_loc->{lat} +$distlat) ;
        my @field = ("tblCoord.ID", "PAON", "SAON", "Street", "Lon", "Lat", "Price", "DateOfTransfer");
        my $from = "(tblTransaction INNER JOIN tblAddress ON tblTransaction.AddressID=tblAddress.ID) INNER JOIN tblCoord ON tblAddress.ID=tblCoord.AddressID";
        my $where =  " WHERE (lon BETWEEN $lon{min} AND $lon{max}) AND " .
                     "(lat BETWEEN $lat{min} AND $lat{max}) AND " .
                     $condition .
                     "tblCoord.Type = \"location\"";
        my $orderby = " ORDER BY DateOfTransfer ";
        my %rah = ( fields=>\@field,
                    table=>$from,
                    where=>$where,
                    orderby=>$orderby);
        my $rah = $this->{_db}->runSqlHash_rtnAoHRef(\%rah);
        return $rah;
    }
    
    sub LRDBaveragePrice{
        my ($this, $rah) = shift;
        my $pricetotal = 0;
        my $size = @{$rah};
        foreach my $rh (@{$rah}){
            $pricetotal += $rh->{Price};
        }   
        my $avgprice = $pricetotal / $size;
        return $avgprice;
    }
}
1;
