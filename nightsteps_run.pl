use strict;
use warnings;
use ns_loopit;

#set up modules

#set up variables
my @listenshape = ([-6,-6], [-15,40], [15,40], [6,-6], [-6,-6]);
my $maxdist = 45;

my $it = ns_loopit->new(    {    
                                listenshape => \@listenshape,
                                logic => "LRDBespeak1",
                                maxdist => $maxdist,
                            });

for (;;){
    $it->iterate;
}


