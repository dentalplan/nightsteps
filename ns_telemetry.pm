package ns_telemetry{
    
    use strict;
    use warnings;
    use ns_gpio;
    use Math::Polygon;
    use Math::Polygon::Calc;
    use GIS::Distance;
    use Math::Trig;

    sub new{
        my $class = shift;
        my $this = {
            _gis => GIS::Distance->new(),
            _gpslog => 'gpsout.txt',
            _gpspath => '/home/pi/nsdata/',
            _compass => ns_gpio->new('c',0),
#            _pypath => '/home/pi/nightsteps/',
        };
        bless $this, $class;
        return $this;
    }

#    sub compass{
#        my $this = shift;
#        my @result = `python $this->{_pypath}$this->{_pycomp}`;
#        chomp $result[1];
#        return $result[1];
#    }

    sub getDegreeToMetre{
        my $this = shift;
        my $l = shift;
        my $DLon = $this->{_gis}->distance( $l->{lat},$l->{lon} => $l->{lat},$l->{lon}+1);
        my $DLat = $this->{_gis}->distance( $l->{lat},$l->{lon} => $l->{lat}+1,$l->{lon});
        my $DLen->{lon} = $DLon->meters();
        $DLen->{lat} = $DLat->meters();
        return $DLen;
    }

    sub getDistanceInMetres{
        my ($this, $l1, $l2) = @_;
        my $distance = $this->{_gis}->distance( $l1->{lat}, $l1->{lon} => $l2->{lat}, $l2->{lon} );
        return $distance->meters;
    }

    sub getPointToPointAngle{
        my ($this, $l1, $l2) = @_;
        my $delta_x = $l2->{lon} - $l1->{lon};
        my $delta_y = $l2->{lat} - $l1->{lat};
        my $radians = atan2($delta_y, $delta_x);
        my $degrees = $radians * (180/pi);
        return $degrees;
    }

    sub getLeftRightPosition{
        my ($this, $angle1, $angle2) = @_;
        my $diff = $angle2 - $angle1;
    }

    sub prepPolyCo{
        my ($this, $rh_loc, $ra_shape) = @_;
        my $DLen = $this->getDegreeToMetre($rh_loc);
        my $poly = Math::Polygon->new(@{$ra_shape});
        my $spun = $poly->rotate(centre=>[0,0], degrees=>$rh_loc->{course});
        my $polyco = $this->convertPolyCoord($spun, $rh_loc, $DLen);

    }

    sub convertPolyCoord{
        my ($this, $poly, $l, $DLen) = @_; 
    #    print "\nchecking incoming from spun\n";
        $this->printPolyPoints($poly);
        my @points = $poly->points;
        my @coord = (); 
        foreach my $p(@points){
            my $lat = ($p->[1]/$DLen->{lat}) + $l->{lat};
            my $lon = ($p->[0]/$DLen->{lon}) + $l->{lon};
            my $rlon = sprintf("%.8f", $lon);
            my $rlat = sprintf("%.7f", $lat);
            print "\n coord point: $rlon,$rlat\n";
            push @coord, [$rlon, $rlat];
        }   
        my $rtn = Math::Polygon->new(@coord);
    #    &printPolyPoints($rtn);
        return $rtn;
    } 

    sub checkPointIsInShape{
        my ($this, $rh_pl, $polyco) = @_;
#        print "test locale: " . $rh_pl->{Lon} . ", " . $rh_pl->{Lat} . "\n";
        my $rtn;
        my @point = ($rh_pl->{Lon}, $rh_pl->{Lat});
        if ($polyco->contains(\@point)){
            $rtn = 1;
        }else{
            $rtn = 0;
        }
        return $rtn;
    }

    sub readGPS{
        my $this = shift;
        open GPSLOG, "<$this->{_gpspath}$this->{_gpslog}" or die $!;
        my @gps = <GPSLOG>;
        my $size = @gps;
        my %loc = ();
        $loc{success} = 0;
    #   print $gps[-1];
        for (my $i=-1; $i>=($size * -1) && $loc{success} == 0; $i-- ){
            chomp $gps[$i];
#            print $gps[$i];
            if($gps[$i] =~ m/.+ TPV, Time: (.+), Lat: (.+), Lon: (.+), Speed: .+, Heading: (.*)/){
                $loc{time} = $1;
                $loc{lat} = $2;
                $loc{lon} = $3;
                $loc{course} = $this->{_compass}->readValue;
#                $loc{course} = $4;
#                print "\n Lon: $loc{lon} Lat: $loc{lat} Course: $loc{course}\n";
                $loc{success} = 1;
            }else{
                $loc{success} = 0;
            }
        }
        close GPSLOG;
#        print "loc success is $loc{success}\n";
        return \%loc;
    }

    sub printPolyPoints{
        my $this = shift;
        my $poly = shift;
        my @rtnpts = $poly->points;
        foreach my $p(@rtnpts){
            print "$p->[0],$p->[1]\n";
        }
    }

}
1;
