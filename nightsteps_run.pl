use strict;
use warnings;
use ns_dbinterface;
use ns_telemetry;
use ns_audinterface;
use Math::Polygon;
use Math::Polygon::Calc;
use Time::Piece;

#set up modules
my $db = ns_dbinterface->new();
my $t = Time::Piece->new();
my $telem = ns_telemetry->new();

#set up variables
my $year = $t->year;
my $DLen = 0;
my @listenshape = ([-6,-6], [-15,40], [15,40], [6,-6], [-6,-6]);

$db->connectDB;
for (my $y=1996; ; $y++){
#for (; ;){
	if ($y > $year){ $y=1996; }
    my $rh_loc = $telem->readGPS;
	if ($rh_loc->{success} == 1){
        print "GPS success!\n";
		my $DLen = $telem->getDegreeToMetre($rh_loc);
		my $poly = Math::Polygon->new(@listenshape);
		my $spun = $poly->rotate(centre=>[0,0], degrees=>$rh_loc->{course});
		my $polyco = $telem->convertPolyCoord($spun, $rh_loc, $DLen);
		my $rah_places = &prepPlaces($rh_loc, $y, $DLen);
		if ($rah_places){
            print "We have places!\n"
            foreach my $rh_pl ($rah_places){
			    if ($telem->checkPointsIsInShape($rh_pl, $polyco) == 1){
                    print "ID " . $rh_pl->{"tblCoord.ID"} .": Property in shape\n";
                    my $address = $rh_pl->{"SAON"} . " " . $rh_pl->{"PAON"}  . " " . $rh_pl->{"Street"};
                    my $price = $rh_pl->{"Price"};
                    my $year = substr $rh_pl->{"DateOfTransfer"}, 0, 4;
			        `espeak "$address sold in $year for $price pounds" --stdout | aplay -D default:Device`;
                }else{
                    print "ID " . $rh_pl->{"tblCoord.ID"} . ": Property not in shape\n";
                }
            }
		}
	}else{
		if ($y==1996){`espeak "waiting on GPS" --stdout | aplay -D default:Device`;}
	}
}

$db->disconnectDB;

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
