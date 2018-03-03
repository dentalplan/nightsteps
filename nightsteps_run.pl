use strict;
use warnings;
use ns_loopit;
use Time::Piece;

#set up modules
my $t = Time::Piece->new();

#set up variables
my @listenshape = ([-6,-6], [-15,40], [15,40], [6,-6], [-6,-6]);

my $it = ns_loopit->new(    {    
                                listenshape => \@listenshape,
                                logic => "LRDBespeak1",
                                dbfile => "lrdb.sqlite",
                                it => 1996,
                                yardstick => $t->year,
                            });

for (;;){
    $it->iterate;
}


