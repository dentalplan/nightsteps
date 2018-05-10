use strict;
use warnings;
use ns_loopit;
use ns_gpio;

#set up modules

#set up variables
my @listenshape = ([-6,-6], [-15,40], [15,40], [6,-6], [-6,-6]);
my $maxdist = 45;
my $switch1 = ns_gpio->new('a', 0);

my $it = ns_loopit->new(    {    
                                listenshape => \@listenshape,
#                                logic => "LRDBespeak1",
                                logic => "LRDBchuck1",
                                maxdist => $maxdist,
                            });

for (my $i=0;;$i++){
    $it->iterate;

    my $read = $switch1->readValue;
    if ($read > 1000){
        $it->{logic} => "LRDBespeak1";
    }else{ 
        $it->{logic} => "LRDBchuck1";
    }

    if ($i==1500){
        $i = 0;
#        open(my $fh, "<", "/home/pi/nsdata/kill.switch");
    }
}


