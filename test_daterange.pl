use strict;
use warnings;
use lib ".";
use ns_gpio;
use Time::HiRes qw( usleep);

my @dateScale = (
    {low=>0, high=>178, range=>'stillToCome'},
    {low=>179, high=>890, range=>'dateRange'},
    {low=>891, high=>1023, range=>'mightHaveBeen'},
);

my %dateRangeProperties = (
        btmPin => 5,
        topPin => 6,
        lowDate => DateTime->new(year=>2007, month=>8, day=>30),
        highDate => DateTime->new(year=>2019, month=>9, day=>1),
        valScale => \@dateScale
    );
my $dr = ns_gpio->newDateRange(\%dateRangeProperties);

while(1){
    my $rh = $dr->readDateRange;
    print "state: $rh->{state}, topdate: $rh->{top}, btmdate: $rh->{btm}\n";
    usleep(100);
}
