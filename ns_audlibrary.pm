package ns_audlibrary{
  use strict;
  use warnings;
  use Switch;

  sub new{
    my $class = shift;
    my $this = {};
    bless $this, $class;
    return $this;
  }

  sub addToScore{
    my ($this, $text, $ra_arg) = @_;
    my $rtn = $ra_arg->[0];
    switch($text){
      case("beat"){$rtn = $this->beat(@{$ra_arg})}
      case("ascRhythm"){$rtn = $this->ascRhythm(@{$ra_arg})}
      case("descRhythm"){$rtn = $this->descRhythm(@{$ra_arg})}
      case("destable"){$rtn = $this->destable(@{$ra_arg})}
      case("destableAll"){$rtn = $this->destableAll(@{$ra_arg})}
    }
    return $rtn;
  }

  sub beat{
    my ($this, $ra_sig, $rh_core, $rh_arg) = @_;
    $ra_sig->[$rh_core->{pos}]->{dur} += $rh_core->{dur};
    if ($rh_core->{force} > 0 && $ra_sig->[$rh_core->{pos}]->{force} == 0){
      $ra_sig->[$rh_core->{pos}]->{force} += 45 + $rh_core->{force};
    }else{
      $ra_sig->[$rh_core->{pos}]->{force} += $rh_core->{force};
    } 
    return $ra_sig;
  }

  sub ascRhythm{
    my ($this, $ra_sig, $rh_core, $rh_arg) = @_;
    $ra_sig->[$rh_core->{pos}]->{dur} += $rh_core->{dur};
    for(my $i=0; $i < ($rh_arg->{repetitions} * $rh_arg->{gap}); $i++){
      if ($rh_core->{force} > 0 && $ra_sig->[$rh_core->{pos}]->{force} == 0){
        $ra_sig->[$rh_core->{pos}]->{force} += 45 + $rh_core->{force};
      }else{
        $ra_sig->[$rh_core->{pos}]->{force} += $rh_core->{force};
      }
    } 
    return $ra_sig;
  }

  sub descRhythm{

  }

  sub destable{

  }

  sub destableAll{

  }

}1;
