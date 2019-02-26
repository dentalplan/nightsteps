use strict;
use warnings;
use ns_loopit;
use ns_gpio;


#set up modules

#set up variables
my @listenshape = ([-6,-6], [-15,40], [15,40], [6,-6], [-6,-6]);
my $maxdist = 45;
my $switch1 = ns_gpio->new('a', 7);
my @switchbands = (
    {low=>60, high=>95, logic=>'LRDBespeak1'},
    {low=>135, high=>165, logic=>'LRDBchuck1'},
    {low=>250, high=>280, logic=>''},
    {low=>410, high=>450, logic=>''},
    {low=>590, high=>635, logic=>''},
    {low=>950, high=>1024, logic=>''}
    );
    

my $it = ns_loopit->new(    {    
                                listenshape => \@listenshape,
                                logic => "dataLogger",
                                maxdist => $maxdist,
                            });
my $lastread = 0;
for (my $i=0;;$i++){

    my $read = $switch1->readValue;
    if ($read + 10 < $lastread || $read - 10 > $lastread){    print "SWITCH READING: $read\n"};
    $lastread = $read;
    foreach my $s (@switchbands){
        if ($read > $s->{low} && $read < $s->{high} && $it->{_logic} ne $s->{logic}){
            $it = ns_loopit->new(    {
                                      listenshape => \@listenshape,
                                      logic => $s->{logic},
                                      maxdist => $maxdist,
                                    });
            print "switching to $s->{logic}\n";
        }
    }

    $it->iterate;

    if ($i==1500){
        $i = 0;
#        print "SWITCH READING: $read\n";
#        open(my $fh, "<", "/home/pi/nsdata/kill.switch");
    }
}



