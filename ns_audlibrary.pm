package ns_audlibrary{
  use strict;
  use warnings;
  use Switch;
  use Math::Round qw(round);

  sub new{
    my $class = shift;
    my $this = {};
    bless $this, $class;
    return $this;
  }

  sub addActionToScore{
    my ($this, $action, $ra_arg) = @_;
    my $rtn = $ra_arg->[0];
    print "Adding $action to $ra_arg->[1]\n";
    switch($action){
      case("beat"){$rtn = $this->beat(@{$ra_arg})}
      case("rhythm"){$rtn = $this->rhythm(@{$ra_arg})}
      case("destable"){$rtn = $this->destable(@{$ra_arg})}
    }
    return $rtn;
  }

  sub addEffectToAction{
      my ($this, $effect, $rh_core, $rh_arg) = @_;
      my $rtn = $rh_core;
      print "adding effect to action\n";
      switch($effect){
        case("destable"){$rtn = $this->destable($rh_core, $rh_arg)}
        case("diminish"){$rtn = $this->diminish($rh_core, $rh_arg)}
      }
      return $rtn;
  }

  sub beat{
    my ($this, $ra_sig, $pos, $rh_core, $rh_arg) = @_;
    $ra_sig->[$pos]->{dur} += $rh_core->{dur};
    my $m = 1;
    $ra_sig = $this->modSigPosition($pos, $m, $ra_sig, $rh_core);
    if ($rh_core->{force} > 0 && $ra_sig->[$pos]->{force} == 0){
      $ra_sig->[$pos]->{force} += 45 + $rh_core->{force};
    }else{
      $ra_sig->[$pos]->{force} += $rh_core->{force};
    } 
    return $ra_sig;
  }

  sub rhythm{
    my ($this, $ra_sig, $pos, $rh_core, $rh_arg) = @_;
    for(my $i=0; $i < ($rh_arg->{repetitions}); $i++){
      $pos += ($i * $rh_arg->{gap});
      my $multiplier = $this->getRhythmMultiplier($i, $rh_arg->{change});
      $ra_sig = $this->modSigPosition($pos, $multiplier, $ra_sig, $rh_core);
      if ($rh_core->{force} > 0 && $ra_sig->[$pos]->{force} < 20){
        $ra_sig->[$pos]->{force} += round(45 + ($rh_core->{force} * $multiplier));
      }else{
        $ra_sig->[$pos]->{force} += round($rh_core->{force} * $multiplier);
      }
    } 
    return $ra_sig;
  }

  sub modSigPosition{
    my ($this, $pos, $multiplier, $ra_sig, $rh_core) = @_;
    foreach my $k (keys %{$rh_core}){
      unless ($k eq 'force'){
        $ra_sig->[$pos]->{$k} += round($rh_core->{$k} * $multiplier);
      }
    }
    return $ra_sig;
  }

  sub getRhythmMultiplier{
    my ($this, $i, $change) = @_;
    my $multiplier = 1;
    if ($change eq "asc"){
      $multiplier += $i/15;
    }elsif ($change eq"desc"){
      $multiplier -= $i/15;
    }
    return $multiplier
  }

  sub destable{
    my ($this, $rh_core, $rh_arg) = @_;
    $rh_core->{syp} += $rh_arg->{strength};
    return $rh_core;
  }

  sub diminish{
    my ($this, $rh_core, $rh_arg) = @_;
    $rh_core->{force} -= $rh_arg->{strength};
    $rh_core->{dur} -= $rh_arg->{strength};
    return $rh_core;
  }

}1;
