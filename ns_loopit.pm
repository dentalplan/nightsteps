 ####################################################################
# This is the central logic hub of nightsteps, where each possible #
# process it can run lives, as used by nightsteps_run. It gives a  #
# subroutinte for a single iteration of the logic, before returning#
# to nightsteps_run to see if the user has switched                #
####################################################################
# Logics                                                           #
# · LRDBespeak1     Reads out house sale data from the Land        #
#                   Registry database                              #
#                                                                  #
# - LRDBchuck1      Produces chuck sonification of Land Registry   #
#                   house sale data and outputs via sound card     #
#                                                                  #
#    
package ns_loopit{
    use strict;
    use warnings;
    use lib ".";
    use ns_testtools;
    use ns_dbinterface;
    use ns_telemetry;
    use ns_audinterface;
    use ns_gpio;
    use ns_logger;
    use Switch;
    use Time::Piece;

    sub new{
        my $class = shift;
        my $rh = shift;
        my $this = {
            _daterange => $rh->{daterange},
            _logic => $rh->{logic},
            _val => $rh->{val},
            _soundmode => $rh->{soundmode},
            _version => $rh->{version},
            _maxdist => $rh->{maxdist},
            _testtools => ns_testtools->new,
            _telem => ns_telemetry->new,
#            _gpio => ns_gpio->new,
            _aud => ns_audinterface->new,
            _db => ns_dbinterface->new,
            _dbfilepath => '/home/pi/nsdata/',
            _t => Time::Piece->new,      
        };
        print "sound mode $this->{_soundmode} \n";
        if ($this->{_soundmode} != 0){
            $this->{_listenshapeLeft} = $rh->{listenshapeLeft};
            $this->{_listenshapeRight} = $rh->{listenshapeRight};
            my @time = localtime(time);
            my $year = $time[5] + 1900;
            print "present year is $year";
            $this->{_maxyear} = $year;
        }else{
            $this->{_listenshape} = $rh->{listenshape};
        }

        bless $this, $class;
        $this->{_logger} = ns_logger->new($this);
        $this->loopitSetup;
        return $this;
    }

    sub loopitSetup{
        my $this = shift;
        switch ($this->{_logic}){
            case "LDDBpercuss1"{ $this->LDDBpercussSetup}
            case "LDDBpercuss2"{ $this->LDDBpercussSetup}
        }
    }

    sub iterate{
        my $this = shift;
        switch ($this->{_logic}){
            case "LDDBpercuss1"{ $this->LDDBpercussIt}
            case "LDDBpercuss2"{ $this->LDDBpercussItPoly}
            case "LDDBpercussDemo"{ $this->LDDBpercussDemoIt}
            case "dataLogger" { $this->dataLoggerIt }
        }
    }


    ######################################################
    ### Logger Block  ######################################
    
    sub dataLoggerIt{
        my $this = shift;
        $this->{_logger}->logData;
    }
    
    ######################################################
    ### LDDB Block  ######################################

    sub LDDBpercussSetup{
        my $this = shift;
        $this->{_db}->connectDB("ldd", 'Pg');
#        $this->{_slidemin} = ns_gpio->new('a', 6);
#        $this->{_slidemax} = ns_gpio->new('a', 4);
        $this->{_aud}->{_minyear} = 2008;
        $this->{_aud}->{_maxyear} = $this->{_t}->year;
    }

    sub LDDBpercussDemoIt{
        my $this = shift;
        my @fn = ("digtest1.o", "digtest2.o", "digtest3.o", "digtestPause.o");
        my $beats = int(rand(4));
        my $size = @fn;
        for(my $i=0; $i<$beats+1; $i++){
            my $f = int(rand($size));
            system "cp /home/pi/nsdata/gpio/$fn[$f] /home/pi/nsdata/gpio/dig1.o";
            system "cp /home/pi/nsdata/gpio/$fn[$f] /home/pi/nsdata/gpio/dig2.o"
        }
        sleep($beats*2);
    }

    sub LDDBpercussIt{
        my $this = shift;
        my $rh_loc = $this->{_telem}->readGPS;
        if ($rh_loc->{success} == 1){
            print "GPS success!\n";
            my $DLen = $this->{_telem}->getDegreeToMetre($rh_loc);
            my $polyco = $this->{_telem}->prepPolyCo($rh_loc, $this->{_listenshape});
            my $rah_places = $this->LDDBprepPlaces($rh_loc, $DLen);
            my $c = $this->{_telem}->{_compass}->readValue;
            if ($rah_places){
                my @do;
                foreach my $rh_pl (@{$rah_places}){
#                    print "$rh_pl->{SAON} $rh_pl->{PAON} $rh_pl->{Street}\n";
                    if ($this->{_telem}->checkPointIsInShape($rh_pl, $polyco) == 1){
                        my $l2 = {
                                    lon => $rh_pl->{lon},
                                    lat => $rh_pl->{lat}
                        };
                        my $absAngle = $this->{_telem}->getPointToPointAngle($rh_loc, $l2);
                        my $relAngle = $c - $absAngle;
                        if ($relAngle > 180) {
                           $relAngle = 360 - $relAngle;
                        }   
                        my $rh_do = {
                                        dist => $this->{_telem}->getDistanceInMetres($rh_loc, $l2),
                                        angle => $relAngle
                        };
#                        print "price is $rh_pl->{Price} vs tune of $pricetune\n";
                        push @do, $rh_do;
                    }
                }
                $this->{_aud}->LDDBpercussBasic1($this->{_maxdist}, \@do);
            }
        }
    }

    sub LDDBpercussItPoly{
        my $this = shift;
        my $rh_loc = $this->{_telem}->readGPS;
        if ($rh_loc->{success} == 1){
            print "GPS success!\n";
            my $DLen = $this->{_telem}->getDegreeToMetre($rh_loc);
            my $rah_places = $this->LDDBprepPolygonPlaces($rh_loc, $DLen);
            if ($this->{_soundmode} != 0){
                @{$rah_places} = sort { $b->{detected_left} <=> $a->{detected_left}    or 
                                        $b->{detected_right} <=> $a->{detected_right}    or 
                                        $a->{distance} <=> $b->{distance} 
                                      } @{$rah_places};
            }else{
                @{$rah_places} = sort { $b->{detected} <=> $a->{detected}    or 
                                        $a->{distance} <=> $b->{distance} 
                                      } @{$rah_places};
            }
            if ($rah_places){
                my @do;
                if ($this->{_soundmode} == 2){
                    foreach my $rh_pl (@{$rah_places}){
                        if ($rh_pl->{detected_left} || $rh_pl->{detected_right}){
                            print "$rh_pl->{permission_id} detected! Left $rh_pl->{detected_left}. Right $rh_pl->{detected_right}.\n\n";
                            push @do, $rh_pl;
                        }
                    }
                    if (@do){
                        $this->{_aud}->LDDBsonicSig($this->{_maxdist}, $this->{_maxyear}, \@do);
                    }else{
                        $this->{_aud}->resetSonicSig;
                    }
                }elsif ($this->{_soundmode} == 1){
                    foreach my $rh_pl (@{$rah_places}){
                        if ($rh_pl->{detected_left} || $rh_pl->{detected_right}){
                            print "$rh_pl->{permission_id} detected! Left $rh_pl->{detected_left}. Right $rh_pl->{detected_right}.\n\n";
                            my $rh_do = {
                                            dist => $rh_pl->{distance},
                                            l => $rh_pl->{detected_left}, 
                                            r => $rh_pl->{detected_right} 
                            };
                            push @do, $rh_do;
                        }
                    }
                    if (@do){
                        my $size = @do;
                        print "$size detected items\n";
                        $this->{_aud}->LDDBpercussStereo($this->{_maxdist}, \@do);
                    }
                }else{
                    foreach my $rh_pl (@{$rah_places}){
                        if ($rh_pl->{detected}){
                            print "detected detected!\n\n";
                            my $rh_do = {
                                            dist => $rh_pl->{distance},
                            };
                            push @do, $rh_do;
                        }
                    }
                    $this->{_aud}->LDDBpercussBasic2($this->{_maxdist}, \@do);
                }
            }elsif ($this->{_soundmode} == 2){
                $this->{_aud}->resetSonicSig; 
            }
        }
    }

    sub LDDBcreateDateCondition{
        my $this = shift; 
        my $rh = $this->{_daterange}->readDateRange;
        my $cond;
        switch ($rh->{state}){
            case (0){   $cond = " AND (status_rc = 'SUBMITTED' or status_rc = 'STARTED') "; }
            case (3){   
                        my $btmyear = $rh->{btm}->strftime('%Y-%m-%d');
                        $cond = " AND (status_rc = 'SUBMITTED' OR status_rc = 'STARTED' OR (status_rc = 'COMPLETED' AND p.completed_date >= '$btmyear')) ";
                    }
            case (4){
                        my $topyear = $rh->{top}->strftime('%Y-%m-%d');
                        my $btmyear = $rh->{btm}->strftime('%Y-%m-%d');
                        $cond = " AND (status_rc = 'COMPLETED' AND p.completed_date <= '$topyear' AND p.completed_date >= '$btmyear') ";
                    }
            case (6){
                        my $topyear = $this->{_daterange}->{_drp}->{highDate};
                        my $btmyear = $this->{_daterange}->{_drp}->{lowDate};
                        $cond = " AND (status_rc = 'DELETED' OR status_rc = 'LAPSED' OR status_rc = 'STARTED' OR status_rc = 'SUBMITTED' OR " . 
                                " (status_rc = 'COMPLETED' AND p.completed_date <= '$topyear' AND p.completed_date >= '$btmyear')) ";
                    }
            case (7){
                        my $topyear = $rh->{top}->strftime('%Y-%m-%d');
                        $cond = " AND (status_rc = 'DELETED' OR status_rc = 'LAPSED' OR (status_rc = 'COMPLETED' AND p.completed_date <= '$topyear')) ";
                    }
            case (8){   $cond = " AND (status_rc = 'DELETED' OR status_rc = 'LAPSED') "; }
        }
        return $cond;
    }

    sub LDDBcreateSwitchCondition{
        my $this = shift;
        my $sql = {  ra_fields => [], from=> ")", where => "", having => "" };
        switch ($this->{_version}){
            case ("all"){
                        }
            case ("shi"){
                            $sql->{ra_fields} = ["SUM(erl.number_of_units) AS existingSocialHousing", "SUM(prl.number_of_units) AS proposedSocialHousing"];
                            $sql->{from} = " LEFT JOIN app_ldd.ld_exist_res_lines AS erl ON p.permission_id = erl.permission_id ) " .
                                           " LEFT JOIN app_ldd.ld_prop_res_lines AS prl ON p.permission_id = prl.permission_id ";
                            $sql->{where} = " AND (erl.tenure_type_rc = 'S' OR prl.tenure_type_rc = 'S') ";
                            $sql->{having} = " AND ((SUM(prl.number_of_units) - SUM(erl.number_of_units)) $this->{_val}) ";
                        }
            case ("osi"){
                            $sql->{ra_fields} = ["SUM(esl.area) AS existingSpace", "SUM(psl.area) AS proposedSpace"];
                            $sql->{from}  = " LEFT JOIN app_ldd.ld_exist_open_space_lines AS esl ON p.permission_id = esl.permission_id ) " . 
                                            " LEFT JOIN app_ldd.ld_prop_open_space_lines AS psl ON p.permission_id = psl.permission_id ";
                            $sql->{having} = " AND ((SUM(psl.area) - SUM(esl.area)) $this->{_val}) ";
                        }
            case ("textsearch"){
                            $sql->{where} =  " AND (p.descr ILIKE '%" . $this->{_val} . "%') " ;
                        }
        }
        return $sql;
    }

    sub LDDBprepPlaces{ 
        my ($this, $rh_loc, $DLen) = @_;
        my $dateCondition = $this->LDDBcreateDateCondition;
        my $rh_sc = $this->LDDBcreateSwitchCondition;
        my $distlon = $this->{_maxdist}/$DLen->{lon};
        my $distlat = $this->{_maxdist}/$DLen->{lat};
        my %lon = (min=>$rh_loc->{lon} - $distlon, max=>$rh_loc->{lon} +$distlon) ;
        my %lat = (min=>$rh_loc->{lat} - $distlat, max=>$rh_loc->{lat} +$distlat) ;
        my @groupby = ("lon", "lat", "p.completed_date", "permission_date", "permission_lapses_date", "p.permission_id");
        my @field;
        push @field, "COUNT(prl_super.permission_id) AS branches";
        push @field, @groupby;
        push @field, @{$rh_sc->{ra_fields}};
        my $having = " HAVING COUNT(prl_super.permission_id) = 0 " . $rh_sc->{having} ;
        my $from = " (((app_ldd.ld_permissions AS p LEFT JOIN app_ldd.ns_permlatlon AS ll ON p.permission_id=ll.permission_id) " . 
                    "LEFT JOIN app_ldd.ld_prop_res_lines AS prl_super ON p.permission_id=prl_super.superseded_permission_id) " . $rh_sc->{from};
        my $where =  " WHERE (lon BETWEEN $lon{min} AND $lon{max}) AND " .
                     "(lat BETWEEN $lat{min} AND $lat{max}) " . 
                      $dateCondition;
        my $orderby = " ORDER BY p.completed_date ";
        my %sqlhash = ( fields=>\@field,
                    table=>$from,
                    where=>$where,
                    groupbys=>\@groupby,
                    having=> $having,
                    orderby=>$orderby);
        my $rah = $this->{_db}->runSqlHash_rtnAoHRef(\%sqlhash, 0);
        #$this->{_testtools}->printRefArrayOfHashes($rah);
        return $rah;
    }

    sub LDDBprepPolygonPlaces{
        my ($this, $rh_loc, $DLen) = @_;
        my $scoopDist = 600; # this is how far away the points are the sniffer can check. For very large sites, this may cause problems.
        my $dateCondition = $this->LDDBcreateDateCondition;
        my $rh_sc = $this->LDDBcreateSwitchCondition;
        my $distlon = $scoopDist/$DLen->{lon};
        my $distlat = $scoopDist/$DLen->{lat};
        #Get the dimensions of the query box we are looking in/
        my %lon = (min=>$rh_loc->{lon} - $distlon, max=>$rh_loc->{lon} +$distlon) ;
        my %lat = (min=>$rh_loc->{lat} - $distlat, max=>$rh_loc->{lat} +$distlat) ;
#        my @groupby = ("lon", "lat", "p.completed_date", "p.permission_id");

        #first we have to do a view that limits what we are looking at, so we don't have to do complicated polygon calcs on the whole DB!
        my $groupby = "lon, lat, p.completed_date, p.permission_id, p.status_rc, exist_res_units_yn, proposed_res_units_yn, exist_non_res_use_yn, proposed_non_res_use_yn";
        my $field = "COUNT(prl_super.permission_id) AS branches, $groupby, date_part('year', p.permission_date) AS permissionyear, date_part('year', p.completed_date) AS completedyear ";
        foreach my $f (@{$rh_sc->{ra_fields}}){ $field .= ", $f";}
        my $from = " (((app_ldd.ld_permissions AS p LEFT JOIN app_ldd.ns_permlatlon AS ll ON p.permission_id=ll.permission_id) " . 
                    "LEFT JOIN app_ldd.ld_prop_res_lines AS prl_super ON p.permission_id=prl_super.superseded_permission_id) " . $rh_sc->{from};
        my $where =  " WHERE (lon BETWEEN $lon{min} AND $lon{max}) AND " .
                     "(lat BETWEEN $lat{min} AND $lat{max}) " . 
                      $dateCondition . $rh_sc->{where};
        my $having = " HAVING COUNT(prl_super.permission_id) = 0 " . $rh_sc->{having} ;
        print "dropping existing view...\n";
        my $sv = $this->{_db}->runsql_rtnSuccessOnly("DROP VIEW IF EXISTS app_ldd.v_perm_widerarea;");
        print "creating view...\n";
        my $sql = "CREATE VIEW app_ldd.v_perm_widerarea AS SELECT $field FROM $from $where GROUP BY $groupby $having;";
        print $sql;
        my $sq = $this->{_db}->runsql_rtnSuccessOnly($sql);
        #print "$sql\n";
        my $ra_geofield = $this->setupPlaceGeoFields($rh_loc);
        # Now we go on to the polygon calcs
        my @fields = ("lat", "lon", "completed_date", "permission_id", "status_rc",               
                      "permissionyear", "completedyear", "exist_res_units_yn",
                      "proposed_res_units_yn", "exist_non_res_use_yn", "proposed_non_res_use_yn"
                     );
        push @fields, @{$ra_geofield};
        $from = "app_ldd.v_perm_widerarea AS v INNER JOIN app_ldd.nsll_ld_permissions_geo AS geo ON v.permission_id=geo.objectid";
        $where = "";
        my %sqlhash = ( fields=>\@fields,
                    table=>$from,
                    where=>"",
#                    groupbys=>\(),
                    having=>"",
                    orderby=>"");
        print "running final query...\n";
        my $rah = $this->{_db}->runSqlHash_rtnAoHRef(\%sqlhash, 1);
        #$this->{_testtools}->printRefArrayOfHashes($rah);
        print "done\n";
        return $rah;
    }

    sub setupPlaceGeoFields{
        my ($this, $rh_loc) = @_;
        my @geofield;
        if ($this->{_soundmode} != 0){
            my @listenPolys = ($this->{_telem}->prepPolyCo($rh_loc, $this->{_listenshapeLeft}),
                              $this->{_telem}->prepPolyCo($rh_loc, $this->{_listenshapeRight}));
            my @poly;
            foreach my $lp (@listenPolys){
                my @listenPts = $lp->points;
                my $polyStr = "";
                foreach my $pt (@listenPts){ $polyStr .= "$pt->[0] $pt->[1],"; }
                chop $polyStr;
                push @poly, $polyStr;
            }
            @geofield = ( "CASE WHEN the_geom IS NOT NULL THEN ST_DWithin(the_geom::geography, 'SRID=4326;POLYGON(($poly[0]))'::geography, 5) " . 
                          "ELSE ST_DWithin(the_geom_pt::geography, 'SRID=4326;POLYGON(($poly[0]))'::geography, 5) END AS detected_left",  
                          "CASE WHEN the_geom IS NOT NULL THEN ST_DWithin(the_geom::geography, 'SRID=4326;POLYGON(($poly[1]))'::geography, 5) " . 
                          "ELSE ST_DWithin(the_geom_pt::geography, 'SRID=4326;POLYGON(($poly[1]))'::geography, 5) END AS detected_right",  
                          "CASE WHEN the_geom IS NOT Null THEN ST_Distance(the_geom::geography, 'SRID=4326;POINT($rh_loc->{lon} $rh_loc->{lat})'::geography) " . 
                          "ELSE ST_Distance(the_geom_pt::geography, 'SRID=4326;POINT($rh_loc->{lon} $rh_loc->{lat})'::geography) END AS distance");
        }else{
            my $listenPoly = $this->{_telem}->prepPolyCo($rh_loc, $this->{_listenshape});
            my @listenPts = $listenPoly->points;
            my $poly = "";
            foreach my $pt (@listenPts){ $poly .= "$pt->[0] $pt->[1],"; }
            chop $poly;
            @geofield = ("CASE WHEN the_geom IS NOT NULL THEN ST_DWithin(the_geom::geography, 'SRID=4326;POLYGON(($poly))'::geography, 5) " . 
                          "ELSE ST_DWithin(the_geom_pt::geography, 'SRID=4326;POLYGON(($poly))'::geography, 5) END AS detected",  
                          "CASE WHEN the_geom IS NOT Null THEN ST_Distance(the_geom::geography, 'SRID=4326;POINT($rh_loc->{lon} $rh_loc->{lat})'::geography) " . 
                          "ELSE ST_Distance(the_geom_pt::geography, 'SRID=4326;POINT($rh_loc->{lon} $rh_loc->{lat})'::geography) END AS distance");
        }
        return \@geofield;
    }

}
1;
