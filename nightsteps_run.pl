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
my $config = ns_config->new;
my $settings = $config->defineControlParameters;
#my @listenshape = ([-6,-6], [-30,75], [-10,80], [10, 80], [30,75], [6,-6], [-6,-6]);
my @listenshape_l = ([-6,-6], [-35,75], [-10,80], [10, 80], [15,70], [0,-8], [-6,-6]);
my @listenshape_r = ([0,-8], [15,70], [10,80], [-10, 80], [30,75], [6,-6], [0,-8]);
my $maxdist = 85;
my $switch1 = ns_gpio->new('a', 7);
my $sm = 2;
my @switchbands = @{$settings->{_switchbands}};
my %dateRangeProperties = %{$settings->{_dateRangeProperties}};
my $dr = ns_gpio->newDateRange(\%dateRangeProperties);
my $it = ns_loopit->new(    {    
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
                                      listenshapeLeft => \@listenshape_l,
                                      listenshapeRight => \@listenshape_r,
                                      daterange => $dr,
                                      logic => $s->{logic},
                                      query => $s->{query},
                                      option => $s->{option},
                                      val => $s->{val},
                                      maxdist => $maxdist,
                                      printmsg => 0
                                    });
            print "switching to $s->{logic}\n";
            $it->loopitSetup;
        }
    }
    $it->iterate;
    usleep(10000);
}



