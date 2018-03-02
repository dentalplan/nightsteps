package ns_telemetry{
    
    use strict;
    use warnings;
    use Math::Polygon;
    use Math::Polygon::Calc;
    use GIS::Distance;

    sub new{
        my $class = shift;
        my $this = {
            _gis => GIS::Distance->new(),
            _gpslog => 'gpsout.txt',
            _gpspath => '/home/pi/nsdata/',
            _pycomp => 'ns_compass.py',
            _pypath => '/home/pi/nightsteps/',
        };
        bless $this, $class;
        return $this;
    }

    sub compass{
        my $this = shift;
        my @result = `python $this->{_pypath}$this->{_pycomp}`;
        chomp $result[1];
        return $result[1];
    }

    sub getDegreeToMetre{
        my $this = shift;
        my $l = shift;
        my $DLon = $this->{_gis}->distance( $l->{lat},$l->{lon} => $l->{lat},$l->{lon}+1);
        my $DLat = $this->{_gis}->distance( $l->{lat},$l->{lon} => $l->{lat}+1,$l->{lon});
        my $DLen->{lon} = $DLon->meters();
        $DLen->{lat} = $DLat->meters();
        return $DLen;
    }

    sub convertPolyCoord{
        my ($this, $poly, $l, $DLen) = @_; 
    #    print "\nchecking incoming from spun\n";
        &printPolyPoints($poly);
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
        print "test locale: " . $rh_pl->{Lon} . ", " . $rh_pl->{Lat} . "\n";
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
        my $f = 0;
        my %loc = ();
    #   print $gps[-1];
        for (my $i=-1; $i>=($size * -1) && $f == 0; $i-- ){
            chomp $gps[$i];
#            print $gps[$i];
            if($gps[$i] =~ m/.+ TPV, Time: .+, Lat: (.+), Lon: (.+), Speed: .+, Heading: .*/){
                $loc{lat} = $1;
                $loc{lon} = $2;
                $loc{course} = $this->compass;
                print "\n Lon: $loc{lon} Lat: $loc{lat}\n";
                $loc{success} = 1;
            }else{
                $loc{success} = 0;
            }
        }
        close GPSLOG;
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
