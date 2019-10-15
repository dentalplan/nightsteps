use strict;
use warnings;
use lib ".";
use ns_loopit;
use ns_gpio;
use DateTime;
use Time::HiRes qw( usleep);


#set up modules

#set up variables
#my @listenshape = ([-6,-6], [-15,40], [15,40], [6,-6], [-6,-6]);
#my $maxdist = 45;
my @listenshape = ([-6,-6], [-30,75], [-10,80], [10, 80], [30,75], [6,-6], [-6,-6]);
my @listenshape_l = ([-6,-6], [-35,75], [-10,80], [10, 80], [15,70], [0,-8], [-6,-6]);
my @listenshape_r = ([0,-8], [15,70], [10,80], [-10, 80], [30,75], [6,-6], [0,-8]);
my $maxdist = 85;
my $switch1 = ns_gpio->new('a', 7);
my $sm = 2;
my @switchbands = (
    {low=>60, high=>95, logic=>'LDDBpercussDemo', version=>'main', val=>'', sm=>$sm},
    {low=>135, high=>165, logic=>'LDDBpercuss2', version=>'textsearch', val=>'change of use', sm=>$sm},
    {low=>250, high=>280, logic=>'LDDBpercuss2', version=>'textsearch', val=>'demoli', sm=>$sm},
    {low=>410, high=>450, logic=>'LDDBpercuss2', version=>'shi', val=>'<= -1', sm=>$sm},
    {low=>590, high=>635, logic=>'LDDBpercuss2', version=>'shi', val=>'>= 1', sm=>$sm},
    {low=>950, high=>1024, logic=>'LDDBpercuss2', version=>'all', val=>'', sm=>$sm}
    );
my @dateScale = (
    {low=>0, high=>178, range=>'stillToCome'},
    {low=>179, high=>890, range=>'dateRange'},
    {low=>891, high=>1023, range=>'mightHaveBeen'},
);
my %dateRangeProperties = (
        btmPin => 5,
        topPin => 6,
        lowDate => DateTime->new(year=>2007, month=>8, day=>31),
        highDate => DateTime->new(year=>2019, month=>9, day=>1),
        valScale => \@dateScale
    );
my $dr = ns_gpio->newDateRange(\%dateRangeProperties);
my $it = ns_loopit->new(    {    
                                listenshape => \@listenshape,
                                daterange => $dr,
                                logic => "dataLogger",
                                maxdist => $maxdist
                            });
my $lastread = 0;
for (my $i=0;;$i++){
    my $read = $switch1->readValue;
    if ($read + 10 < $lastread || $read - 10 > $lastread){    print "SWITCH READING: $read\n"};
    $lastread = $read;
    foreach my $s (@switchbands){
        if ($read > $s->{low} && $read < $s->{high} && ($it->{_logic} ne $s->{logic} || $it->{_version} ne $s->{version} || $it->{_val} ne $s->{val})){
            $it = ns_loopit->new(   {
                                      listenshape => \@listenshape,
                                      listenshapeLeft => \@listenshape_l,
                                      listenshapeRight => \@listenshape_r,
                                      soundmode => $s->{sm},
                                      daterange => $dr,
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
    usleep(20000);
    if ($i==1500){
        $i = 0;
#        print "SWITCH READING: $read\n";
#        open(my $fh, "<", "/home/pi/nsdata/kill.switch");
    }
}



