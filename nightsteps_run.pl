use strict;
use warnings;
use lib ".";
use lib "/home/pi/nsdata/";
use ns_loopit;
use ns_config;
use ns_gpio;
use DateTime;
use Time::HiRes qw( usleep);


#set up modules

#set up variables
#my @listenshape = ([-6,-6], [-15,40], [15,40], [6,-6], [-6,-6]);
#my $maxdist = 45;
my $config = ns_config->new;
my $settings = $config->defineControlParameters;
#my @listenshape = ([-6,-6], [-30,75], [-10,80], [10, 80], [30,75], [6,-6], [-6,-6]);
my @listenshape_l = ([-6,-6], [-35,75], [-10,80], [10, 80], [15,70], [0,-8], [-6,-6]);
my @listenshape_r = ([0,-8], [15,70], [10,80], [-10, 80], [30,75], [6,-6], [0,-8]);
my $maxdist = 85;
my $switch1 = ns_gpio->new('a', 7);
my $sm = 2;
my @switchbands = @{$settings->{_switchbands}};
#my @switchbands = (
#    {low=>35, high=>110, logic=>'percussDemo', version=>'main', val=>'', sm=>$sm},
#    {low=>135, high=>200, logic=>'LDDBpercuss2', version=>'textsearch', val=>'change of use', sm=>$sm},
#    {low=>240, high=>350, logic=>'LDDBpercuss2', version=>'textsearch', val=>'demoli', sm=>$sm},
#    {low=>400, high=>500, logic=>'LDDBpercuss2', version=>'shi', val=>'<= -1', sm=>$sm},
#    {low=>580, high=>760, logic=>'LDDBpercuss2', version=>'shi', val=>'>= 1', sm=>$sm},
#    {low=>930, high=>1024, logic=>'LDDBpercuss2', version=>'all', val=>'', sm=>$sm}
#    );

my %dateRangeProperties = %{$settings->{_dateRangeProperties}};
#my @dateScale = (
#    {low=>0, high=>178, range=>'stillToCome'},
#    {low=>179, high=>890, range=>'dateRange'},
#    {low=>891, high=>1023, range=>'mightHaveBeen'},
#);
#my %dateRangeProperties = (
#        btmPin => 5,
#        topPin => 6,
#        lowDate => DateTime->new(year=>2007, month=>8, day=>31),
#        highDate => DateTime->new(year=>2019, month=>9, day=>1),
#        valScale => \@dateScale
#    );
my $dr = ns_gpio->newDateRange(\%dateRangeProperties);
my $it = ns_loopit->new(    {    
#                                listenshape => \@listenshape,
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
        if ($read > $s->{low} && $read < $s->{high} && ($it->{_logic} ne $s->{logic} || $it->{_option} ne $s->{option} || $it->{_query} ne $s->{query})){
            $it = ns_loopit->new(   {
#                                      listenshape => \@listenshape,
                                      listenshapeLeft => \@listenshape_l,
                                      listenshapeRight => \@listenshape_r,
                                      daterange => $dr,
                                      logic => $s->{logic},
                                      query => $s->{query},
                                      option => $s->{option},
                                      val => $s->{val},
                                      maxdist => $maxdist,
                                    });
            print "switching to $s->{logic}\n";
            $it->loopitSetup;
        }
    }
    $it->iterate;
    usleep(20000);
    if ($i==1500){
        $i = 0;
#        print "SWITCH READING: $read\n";
#        open(my $fh, "<", "/home/pi/nsdata/kill.switch");
    }
}



