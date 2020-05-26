
package ns_config{
  use strict;
  use warnings;
  use DateTime;
  use JSON;

  sub new{
    my $class = shift;
    my $rh = shift;
    my $this = {};
    bless $this, $class;
    $this->{_json} = JSON->new;
    $this = $this->defineControlParameters;
  }

  sub defineControlParameters{
    my $this = shift;
    my %database = (databaseName=>'ldd', databaseType=>'Pg');
    my $qs = $this->buildQuerySetup("/home/pi/nsdata/querydefs/ldd1.json");
    my @switchbands = (
        {low=>35, high=>110, logic=>'percussDemo'},
        {low=>135, high=>200, logic=>'percussIt', query=>$qs, option=>"textsearch-changeofuse"},
        {low=>240, high=>350, logic=>'percussIt', query=>$qs, option=>"textsearch-demolition"},
        {low=>400, high=>500, logic=>'percussIt', query=>$qs, option=>"socialhousing-decrease"},
        {low=>580, high=>760, logic=>'percussIt', query=>$qs, option=>"socialhousing-increase"},
        {low=>930, high=>1024, logic=>'percussIt', query=>$qs, option=>0}
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
    $this->{_switchbands} = \@switchbands;
    $this->{_dateRangeProperties} = \%dateRangeProperties;
    return $this;
  }

  sub buildQuerySetup{      
    my $this = shift;
    my $filename = shift;
    print "$filename\n";
    my $json_text = do {
      open(my $json_fh, "<:encoding(UTF-8)", $filename)
        or die("Can't open \$filename\": $!\n");
      local $/;
      <$json_fh>
    };
#    print "initial processing\n";
#    print $json_text;
    my $qs = $this->{_json}->decode($json_text);
    return $qs;
  }
}1;

