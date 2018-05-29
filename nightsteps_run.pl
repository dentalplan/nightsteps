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
                                logic => "LRDBchuck1",
                                maxdist => $maxdist,
                            });

for (my $i=0;;$i++){

#    my $read = $switch1->readValue;
#    print "SWITCH READING: $read\n";
#    print "LOGIC: $it->{_logic}\n";
#    if ($read > 900){
#        print "over 900\n";
#        if ($it->{_logic} ne "LRDBespeak1"){
#            $it = ns_loopit->new(    {
#                                      listenshape => \@listenshape,
#                                      logic => "LRDBespeak1",
#                                      maxdist => $maxdist,
#                                    });
#
#        };
#    }else{ 
#        print "under 900\n";
#        if ($it->{_logic} ne "LRDBchuck1"){
#            $it = ns_loopit->new(    {
#                                    listenshape => \@listenshape,
#                                    logic => "LRDBchuck1",
#                                    maxdist => $maxdist,
#                                  });
#
#        }
#    }

    $it->iterate;

    if ($i==1500){
        $i = 0;
#        open(my $fh, "<", "/home/pi/nsdata/kill.switch");
    }
}



