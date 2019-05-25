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
    {low=>60, high=>95, logic=>'LDDBpercussDemo', version=>'main', val=>''},
    {low=>135, high=>165, logic=>'LRDBchuck1', version=>'main', val=>''},
    {low=>250, high=>280, logic=>'LRDBespeak1', version=>'textsearch', val=>'demolition'},
    {low=>410, high=>450, logic=>'LDDBpercuss1', version=>'shi', val=>'<-1'},
    {low=>590, high=>635, logic=>'LDDBpercuss1', version=>'osi', val=>'>+1'},
    {low=>950, high=>1024, logic=>'LDDBpercuss1', version=>'all', val=>''},
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
        if ($read > $s->{low} && $read < $s->{high} && ($it->{_logic} ne $s->{logic} || $it->{_version} ne $s->{version} || $it->{_val} ne $s->{val})){
            $it = ns_loopit->new(    {
                                      listenshape => \@listenshape,
                                      logic => $s->{logic},
                                      version => $s->{version},
                                      val => $s->{val},
                                      maxdist => $maxdist,
                                    });
            print "switching to $s->{logic}\n";
            $it->loopitSetup;
        }
    }
    $it->{_logger}->logData();
    $it->iterate;

    if ($i==1500){
        $i = 0;
#        print "SWITCH READING: $read\n";
#        open(my $fh, "<", "/home/pi/nsdata/kill.switch");
    }
}



