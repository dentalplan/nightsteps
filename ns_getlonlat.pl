use strict;
use warnings;
use ns_dbinterface;
use XML::Simple;
use Time::HiRes;

my $db = ns_dbinterface->new;
$db->connectDB;
my $postcode = "BN2 3FR";
my $rsql;
my @fields = ("ID", "PAON", "SAON", "Street", "Locality", "TownCity", "Postcode");
$rsql->{fields} = \@fields;
$rsql->{table} = "tblAddress";
$rsql->{where} = " WHERE Postcode = '$postcode'";
$rsql->{orderby} = " ORDER BY PAON";
my $rah_add = $db->runSqlHash_rtnAoHRef($rsql);
foreach my $rh (@{$rah_add}){
    &printHash($rh);
    &processGeocodeXML($rh);
}


sub makeGeocodeRequest{

    my $rh = shift;
    my $add;
#    if (length($rh->{SAON}) > 0){
#        $add .= $rh->{SAON} . ",+";
#    }
    if (length($rh->{PAON}) > 0){
        $add .= $rh->{PAON} . "+";
    }
    if ($rh->{Street}){
        $add .= $rh->{Street} . ",+";
        $add .= $rh->{TownCity};
    }elsif($rh->{Locality}){
        $add .= $rh->{Locality} . ",+";
        $add .= $rh->{TownCity};
    }
    
    $add =~ s/ /+/g;
    my $geo = "https://maps.googleapis.com/maps/api/geocode/xml?address=" . $add . "&key=AIzaSyDjEtpWb5AgzlTghbbJ5LVMdzaQmP1bl2M";
    return $geo;

}

sub processGeocodeXML{

    my $rh = shift;
    my $sql = "SELECT tblCoord.ID FROM tblCoord LEFT JOIN tblAddress ON tblCoord.AddressID=tblAddress.ID " .
              "WHERE tblAddress.PAON =\"$rh->{PAON}\" AND  tblAddress.SAON =\"$rh->{SAON}\" AND " .
              "tblAddress.Street =\"$rh->{Street}\" AND  tblAddress.TownCity =\"$rh->{TownCity}\"";
    my $id = $db->runsql_rtnScalar($sql);
    unless ($id){
        my $geo = &makeGeocodeRequest($rh);
        print $geo . "\n";
        `rm geo.xml`;
        my $cmd = "wget -O geo.xml \"$geo\"";
        print "RUN: $cmd\n";
        my $run = `$cmd`;
        Time::HiRes::usleep(100000);
        my $xml = new XML::Simple;
        my $xrh = $xml->XMLin("geo.xml");
        print "No Coord detected\n";
        my $id = &processGeoLocation($rh, $xrh);
        print "result $id\n";
        &processGeoViewport($rh, $xrh);       
    }else{
        print "Coord detected\n";  
    }

}

sub processGeoLocation{

    my ($rh, $xrh) = @_;
    if ($xrh->{status} eq "OK"){
        my $type = "location";
        my $fields = "AddressID, Lon, Lat, Type, Direction";
        my $l = $xrh->{result}->{geometry}->{location};
        my $lon = $l->{lng};
        my $lat = $l->{lat};
        my $dir = "point";
        my $values = "$rh->{ID}, $lon, $lat, \"$type\", \"$dir\"";
        print "$fields\n$values\n";
        my %in_sql = (
                            fields=>$fields,
                            values=>$values,
                            table=>"tblCoord"
                    );
        my $id = $db->insertValues(\%in_sql); 
        return $id;
   }else{ return "#FAIL";} 
}


sub processGeoViewport{

    my ($rh, $xrh) = @_;
    if ($xrh->{status} eq "OK"){
        my $fields = "AddressID, Lon, Lat, Type, Direction";
        my $type = "viewport";
        my $v = $xrh->{result}->{geometry}->{viewport};
        foreach my $key (keys %{$v}){
            my $lon = $v->{$key}->{lng};
            my $lat = $v->{$key}->{lat};
            my $dir = $key;
            my $values = "$rh->{ID}, $lon, $lat, \"$type\", \"$dir\"";
            print "$fields\n$values\n";
            my %in_sql = (
                            fields=>$fields,
                            values=>$values,
                            table=>"tblCoord"
                        );
            $db->insertValues(\%in_sql);
        }
   }else{ return "#FAIL";} 
}


sub printArray{

    my $ra = shift;
    foreach my $e(@{$ra}){
        print "$e\n";
    }
    print "\n";

}


sub printHash{

    my $rh = shift;
    foreach my $key (keys %{$rh}) {
        my $value = $rh->{$key};
        print "$key = \t$value\n";
    }
    print "\n";

}

