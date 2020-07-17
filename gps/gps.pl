use strict;
#use warnings;
use Net::GPSD3;
use Data::Dumper qw{Dumper};

#sleep 5; #tells it to wait 5 sec so it doesn't crash out due to lack of time value
my $obj=Net::GPSD3->new(host=>"localhost", port=>"2947");
$obj->watch;
#for(my $i=0; $i<300; $i++){
#  my $pt=$obj->poll;
#  my $fix=$pt->fix;
#  #  print $fix;
#  #  &printHash($fix);
#  print "\n############ POLL OBJECT #################\n\n";
#  print Dumper($pt);
#  print "\n############ FIX OBJECT #################\n\n";
#  print Dumper($fix);
#  # # print "tpv:";
#  # # &printArray($pt->{st});
#  sleep(1);
#}
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
 
