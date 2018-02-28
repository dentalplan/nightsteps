use strict;
use warnings;
use ns_dbinterface;
use Math::Polygon;
use Math::Polygon::Calc;
use GIS::Distance;
use Time::Piece;

#set up modules
my $gis = GIS::Distance->new();
my $db = ns_dbinterface->new;
my $t = Time::Piece->new();

#set up variables
my $year = $t->year;
my $DLen = 0;
my $path = "/home/pi/nightstep/";
my $pycomp = "ns_compass.py";
my $gpslog = "gpsout.txt";
my @listenshape = ([-6,-6], [-15,40], [15,40], [6,-6], [-6,-6]);


$db->connectDB;
for (my $y=1996; ; $y++){
#for (; ;){
	if ($y > $year){ $y=1996; }
	my @compass = `python $path$pycomp`;
	chomp $compass[1];
	open GPSLOG, "<$path$gpslog" or die $!;
	my @gps = <GPSLOG>;
	my $size = @gps;
	my $f = 0;
	my %loc = ();
#	print $gps[-1];
	for (my $i=-1; $i>=($size * -1) && $f == 0; $i-- ){
		chomp $gps[$i];
		print $gps[$i];
		if($gps[$i] =~ m/.+ TPV, Time: .+, Lat: (.+), Lon: (.+), Speed: .+, Heading: .*/){
			$loc{lat} = $1;
			$loc{lon} = $2;
			$loc{course} = $compass[1];
			print "\n Lon: $loc{lon} Lat: $loc{lat}\n";
			$f = 1;
		}
	}
	close GPSLOG;
	
	if ($f == 1){
		my $l = \%loc;
		my $DLen = &getDegreeToMetre($l);
		my $poly = Math::Polygon->new(@listenshape);
		my $spun = $poly->rotate(centre=>[0,0], degrees=>$l->{course});
		my $polyco = &convertPolyCoord($spun, $l, $DLen);
		my $a_places = &prepPlaces($l, $y, $DLen);
		if ($a_places){
			&checkPointsInShape($a_places, $polyco);
		}
	}else{
		if ($y==1996){`espeak "waiting on GPS" --stdout | aplay -D default:Device`;}
	}
}

sub getDegreeToMetre{

	my $l = shift;
	my $DLon = $gis->distance( $l->{lat},$l->{lon} => $l->{lat},$l->{lon}+1);
	my $DLat = $gis->distance( $l->{lat},$l->{lon} => $l->{lat}+1,$l->{lon});
	my $DLen->{lon} = $DLon->meters();
	$DLen->{lat} = $DLat->meters();
	return $DLen;

}

sub checkPointsInShape{
    my ($a_pl, $polyco) = @_;
#    print "\nchecking point is in shape\n";
#    &printPolyPoints($polyco);
    my $size = @{$a_pl};
    for (my $i=0; $i<$size; $i++){
        print "test locale $i: " . $a_pl->[$i]->{Lon} . ", " . $a_pl->[$i]->{Lat} . "\n";
        my @point = ($a_pl->[$i]->{Lon}, $a_pl->[$i]->{Lat});
        if ($polyco->contains(\@point)){
#        if(Math::Polygon::Calc->polygon_contains_point(\@point, @{$polyco})){
            print "ID " . $a_pl->[$i]->{"tblCoord.ID"} .": Property in shape\n";
			my $address = $a_pl->[$i]->{"SAON"} . " " . $a_pl->[$i]->{"PAON"}  . " " . $a_pl->[$i]->{"Street"};
			my $price = $a_pl->[$i]->{"Price"};
			my $year = substr $a_pl->[$i]->{"DateOfTransfer"}, 0, 4;
			`espeak "$address sold in $year for $price pounds" --stdout | aplay -D default:Device`
        }else{
            print "ID " . $a_pl->[$i]->{"tblCoord.ID"} . ": Property not in shape\n";
        }
    }
}
$db->disconnectDB;
#($A,$B,$C) = $polyco->point(0,1,2);
#print "A: " . $A->[0] . "," . $A->[1] . "  B: " . $B->[0] . "," . $B->[1] . "  C: " . $C->[0] . "," . $C->[1] . "\n";

sub convertPolyCoord{

    my ($poly, $l, $DLen) = @_;
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


sub printPolyPoints{
 
    my $poly = shift;
    my @rtnpts = $poly->points;
    foreach my $p(@rtnpts){
        print "$p->[0],$p->[1]\n";
    }

}


sub prepPlaces{ 

    my ($rh_loc, $year, $DLen) = @_;
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
    my $rah = $db->runSqlHash_rtnAoHRef(\%rah);
    return $rah;

}
