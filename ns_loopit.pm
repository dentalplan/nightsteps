package ns_loopit{
    use strict;
    use warnings;
    use ns_dbinterface;
    use ns_telemetry;
    use ns_audinterface;
    use Math::Polygon;
    use Math::Polygon::Calc;
    use Switch;

    sub new{
        my $class = shift;
        my $rh = shift;
        my $this = {
            _listenshape => $rh->{listenshape},
            _logic => $rh->{logic},
            _it => $rh->{it},
            _yardstick => $rh->{yardstick},
            _telem => ns_telemetry->new,
            _aud => ns_audinterface->new,
            _db => ns_dbinterface->new,
        };
        $this->{_db}->connectDB($rh->{dbfile});
        bless $this, $class;
        return $this;
    }

    sub iterate{
        my $this = shift;
        switch ($this->{_logic}){
            case "LRDBespeak1" { $this->LRDBespeak1It }
        }
    }

    sub LRDBespeak1It{
        my $this = shift;
        if ($this->{_it} > $this->{_yardstick}){ $this->{_it}=1996; }
        my $rh_loc = $this->{_telem}->readGPS;
        if ($rh_loc->{success} == 1){
            print "GPS success!\n";
            my $DLen = $this->{_telem}->getDegreeToMetre($rh_loc);
            my $polyco = $this->{_telem}->prepPolyCo($rh_loc, $this->{_listenshape});
            my $rah_places = $this->LRDBprepPlaces($rh_loc, $this->{_it}, $DLen);
            if ($rah_places){
                print "We have places!\n";
    #            print $rah_places->[0]->{PAON};
                foreach my $rh_pl (@{$rah_places}){
                    if ($this->{_telem}->checkPointIsInShape($rh_pl, $polyco) == 1){
                        print "ID " . $rh_pl->{"tblCoord.ID"} .": Property in shape\n";
                        $this->{_aud}->LRDBespeak1($rh_pl);
                    }else{
                        print "ID " . $rh_pl->{"tblCoord.ID"} . ": Property not in shape\n";
                    }
                }
            }
        }else{
            if ($this->{_it}==1996){$this->{_aud}->espeakWaitOnGPS;}
        }
        $this->{_it}++;
    }

    sub LRDBprepPlaces{ 
        my ($this, $rh_loc, $year, $DLen) = @_;
    #    my ($rh_loc, $DLen) = @_;
        my $distmet = 20;
        my $distlon = $distmet/$DLen->{lon};
        my $distlat = $distmet/$DLen->{lat};
        my %lon = (min=>$rh_loc->{lon} - $distlon, max=>$rh_loc->{lon} +$distlon) ;
        my %lat = (min=>$rh_loc->{lat} - $distlat, max=>$rh_loc->{lat} +$distlat) ;
        my @field = ("tblCoord.ID", "PAON", "SAON", "Street", "Lon", "Lat", "Price", "DateOfTransfer");
        my $from = "(tblTransaction INNER JOIN tblAddress ON tblTransaction.AddressID=tblAddress.ID) INNER JOIN tblCoord ON tblAddress.ID=tblCoord.AddressID";
        my $where =  " WHERE (lon BETWEEN $lon{min} AND $lon{max}) AND " .
                     "(lat BETWEEN $lat{min} AND $lat{max}) AND " .
                     "DateOfTransfer Like \"$year%\" AND " .
                     "tblCoord.Type = \"location\"";
        my $orderby = " ORDER BY DateOfTransfer ";
        my %rah = ( fields=>\@field,
                    table=>$from,
                    where=>$where,
                    orderby=>$orderby);
        my $rah = $this->{_db}->runSqlHash_rtnAoHRef(\%rah);
        return $rah;
    }

}
1;
