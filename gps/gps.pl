use strict;
#use warnings;
use Net::GPSD3;
use Data::Dumper qw{Dumper};

#sleep 5; #tells it to wait 5 sec so it doesn't crash out due to lack of time value
my $obj=Net::GPSD3->new(host=>"localhost", port=>"2947");
my $pt=$obj->watch;
#print Dumper($pt);
#my $j=$obj->json;
#print Dumper($j);


sub printHash{

    my $rh = shift;
    foreach my $key (keys %{$rh}) {
        my $value = $rh->{$key};
        print "$key = \t$value\n";
    }
    print "\n";

}

sub printArray{

    my $ra = shift;
    foreach my $e(@{$ra}){
        print "$e\n";
    }
    print "\n";

}
 
