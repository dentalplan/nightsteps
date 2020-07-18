package ns_audinterface{
#the audio interface layer translates data structures into audio parameters;
    use strict;
    use warnings;
    use lib ".";
    use Switch;
    use ns_testtools;
    use ns_audlibrary;
    use Math::Round qw(round);
    use Data::Dumper;

    sub new {
        my ($class, $son, $thres, $option) = @_;
        my $ra_rules = $son->{rules};
        if ($son->{optionSpecificRules}->{$option}){
          push @{$ra_rules}, @{$son->{optionSpecificRules}->{$option}};
        }
        my $rh_effects = $son->{effectSets};
        if ($son->{optionSpecificEffects}->{$option}){
          $rh_effects = {$rh_effects, $son->{optionSpecificEffects}->{$option}};
        }
        my $this  = {
#            _mode => shift,
            _sonicspace=>1152,
            _scorelines=>24,
            _linedur=>48,
            _standardbeatdur=>4,
            _thres => $thres,
            _sonification => $son,
            _rules => $ra_rules,
            _effects=> $rh_effects,
            _testtools => ns_testtools->new,
            _audlib => ns_audlibrary->new,
            _outputs => [{path=>'/home/pi/nsdata/gpio/dsig_l.o', field=>'detected_left', ra_sig=>[]}, 
                         {path=>'/home/pi/nsdata/gpio/dsig_r.o', field=>'detected_right', ra_sig=>[]}],
            _gpoutpath => '/home/pi/nsdata/gpio/'
        };
        print "blessing aud\n";
        bless $this, $class;
        return $this;
    }

    sub LDDBpercussBasic1{
        my ($this, $maxdist, $rah_do) = @_;
        my $out = 1;
        my $file = $this->{_gpoutpath} . "dig$out.o";
        my @clicks = ();
        foreach my $rh_do (@{$rah_do}){
            my $click = (($maxdist + 18 - $rh_do->{dist} - ($rh_do->{angle}/10)) / $maxdist);
            push @clicks, $click;
        }
        $this->digClicks($file, \@clicks);
    }
    
    sub LDDBpercussBasic2{
        my ($this, $maxdist, $rah_do, $stereo) = @_;
        my $out = 1;
        my $file = $this->{_gpoutpath} . "dig$out.o";
        my @clicks = ();
        foreach my $rh_do (@{$rah_do}){
            my $click = (($maxdist - $rh_do->{dist}) / $maxdist);
            push @clicks, $click;
        }
        $this->digClicks($file, \@clicks);
    }


    sub physSendInstructions{
        my ($this, $file, $ra_instr) = @_;
        open (FO, ">", $file);
        foreach my $l (@{$ra_instr}){
            print FO "$l\n";
        }
        close FO;
    }

    sub LDDBpercussStereo{
        my ($this, $maxdist, $rah_do) = @_; #strength, 
        my $mode = 't';
        my $high = 'o07-';
        my $off = 'o00-';
        my $outtype = "pwm";
        my $size = @{$rah_do};
        my @lines1 = ($mode);
        my @lines2 = ($mode);
        for (my $i=0; $i<$size; $i++){
            my $click = (($maxdist - $rah_do->[$i]->{dist}) / $maxdist);
            my $frc = int($click * 20);
            my $rep = round($click * 3) + 1;
            my $h = 15 + $frc;
            my $l = 55 - $frc;
            if ($rah_do->[$i]->{r}){
                for (my $k=0; $k<$rep;$k++){
                    push @lines1, "$high$h";
                    push @lines1, "$off$l";
                }
            }else{
                my $t = ($h + $l) * $rep;
                push @lines1, "$off$t";
            }
            if ($rah_do->[$i]->{l}){
                for (my $k=0; $k<$rep;$k++){
                    push @lines2, "$high$h";
                    push @lines2, "$off$l";
                }
            }else{
                my $t = ($h + $l) * $rep;
                push @lines2, "$off$t";
            }
            push @lines1, $off . "200";
            push @lines2, $off . "200";
        }
        push @lines1, $off . "500";
        push @lines2, $off . "500";
        $this->physSendInstructions($this->{_gpoutpath} . $outtype . "1.o", \@lines1);
        $this->physSendInstructions($this->{_gpoutpath} . $outtype . "2.o", \@lines2);
    }

    sub digClicks{
        my ($this, $file, $ra_clicks) = @_; #strength, 
        my $mode = 't';
        my $size = @{$ra_clicks};
        my @lines = ($mode);
        for (my $i=0; $i<$size; $i++){
            my $frc = int($ra_clicks->[$i] * 20);
            my $rep = round($ra_clicks->[$i] * 3) + 1;
            my $h = 15 + $frc;
            my $l = 55 - $frc;
            for (my $r=0; $r<$rep;$r++){
                push @lines, "h$h";
                push @lines, "l$l";
            }
            push @lines, "l200";
        }
        push @lines, "l500";
        $this->physSendInstructions($file, \@lines);
    }

    sub digBeat{
        my ($this, $out, $mode, $rep, $style) = @_;
        my $file = $this->{_gpoutpath} . "dig$out.o";
        my @instr = ($mode);
        my ($l, $h, $r);
        if ($style eq "a"){
            $l = "l30";
            $h = "h40";
            $r = 3;
        }elsif ($style eq "b"){
            $l = "l30";
            $h = "h60";
            $r = 2;
        }
        for (my $i=0; $i < $rep; $i++){
            push @instr, "l150"; 
            for (my $k=0; $k < $r; $k++){
            push @instr, $h;
            push @instr, $l;
            }
        }
        push @instr, "l900";
        $this->physSendInstructions($file, \@instr);
    }

    sub generateEmptySig{
        #my ($this, $siglen) = @_;
        my ($this) = @_;
        my $siglen = $this->{_sonification}->{beats};
        my @ra;
        for (my $i=0; $i<$siglen; $i++){
            my %instr = (force=>0, dur=>0, fmod=>0, dvar=>0, syp=>0, offset=>0);
            push @ra, \%instr;
        }
        return \@ra;
    }

    sub generateEmptyDsig{
        # Sets up an array of arrays of arrays (seriously) for the whole track.
        my ($this) = @_;
        my $dsiglen = $this->{_sonification}->{beats};
        my @ra;
        for (my $i=0; $i<$dsiglen; $i++){
            my @instr = ([]); # Each array contains parallel instruction sets for the datasniffer output
            push @ra, \@instr;# dsig.py does the work of combining these instructions rather than sorting the whole score here.
        }
        return \@ra;
    }

    sub fillOutDsig{
        # This sub will add 'do not strike' instructions to every empty point in the instruction array
        my ($this, $ra_sig) = @_;
        my $dsiglen = $this->{_sonification}->{beats};
        for (my $i=0; $i<$dsiglen; $i++){
            unless ($ra_sig->[$i]->[0]->[0]){
                my $nullins = {force =>0, dur=>64};
                push @{$ra_sig->[$i]->[0]}, $nullins;
            }
        }
        return $ra_sig
    }

    sub convertAoHtoInstrText{
        my ($this, $rah) = @_;
        my @ra;
        foreach my $rh (@{$rah}){
            my $s = "f$rh->{force}-d$rh->{dur}-m$rh->{fmod}-v$rh->{dvar}-s$rh->{syp}-o$rh->{offset}";
            print "$s\n";
            push @ra, $s
        }
        return \@ra;
    }

    sub convertAoHtoDsigInstrText{
        #This converts the array of instructions in Nightsteps to a format that dsig.py can read and 
        #feed to the outputs.
        my ($this, $ra) = @_;
        my @ra_out;
        foreach my $ra_line (@{$ra}){
          my $text = "";
          foreach my $ra_set (@{$ra_line}){
            foreach my $rh (@{$ra_set}){
              my $text .= "d$rh->{dur}\@f$rh->{force}-";
            }
            chop $text;
            $text .= "|";
          }
          chop $text;
          $text .= "\n";
          push @ra_out, $text;
        }
        return \@ra_out;
    }

    sub resetSonicSig{
        my $this = shift;
        foreach my $o (@{$this->{_outputs}}){
          my $ra = $this->generateEmptySig();
          my $rat = $this->convertAoHtoInstrText($ra);
          $this->physSendInstructions($o->{path}, $rat);
        }
    }

    sub sonicDsig{
        my ($this, $maxdist, $rah_do) = @_;
        foreach my $o (@{$this->{_outputs}}){
          $o->{ra_sig} = $this->generateEmptyDsig();
        }
        my $outputNumber = @{$this->{_outputs}};
        my $closestdistance = $maxdist; #this value works out which is this closest detected object.
        my @rules;
        push @rules, $this->{_sonification}->{rules};
        foreach my $d (@{$rah_do}){
          my $detected = 0;
          my @detectedOnOutput;
          my $offCentreDistAdj = 10 * $outputNumber; #This is an adjustment to distance based on how 'in focus' an object is.
          foreach my $o (@{$this->{_outputs}}){
            if ($d->{$o->{field}}){
              $offCentreDistAdj -= 10;
              $detected++;
              push @detectedOnOutput, $o; #places reference to output in 'detected output' so it can have appropriate actions
                                          #added to its score.
            }
          }
          if ($detected >= $outputNumber && $d->{distance} < $closestdistance){
            $closestdistance = $d->{distance};
          }
          my $rh_adj = { dur => -2 + int($this->getDistanceRatio($d->{distance} + $offCentreDistAdj, $maxdist + 10, 5, 1) * 7),
                         force => int($this->getDistanceRatio($d->{distance}, $maxdist, 4, 1) * 40),
                      };
          $this->applyRulesToSig($this, $d, $rh_adj, \@detectedOnOutput);
        }
        $this->setSpeedDivider($closestdistance, $maxdist);
        foreach my $o (@{$this->{_outputs}}){
          print "Writing output to $o->{path}\n";
          my $outsig = $this->fillOutDsig($o->{ra_sig});
          my $ra_sigt = $this->convertAoHtoDisgInstrText($outsig);
          $this->physSendInstructions($o->{path}, $ra_sigt);
        }
    }

    sub sonicSig{
        my ($this, $maxdist, $rah_do) = @_;
        #$this->{_testtools}->printRefArrayOfHashes($rah_do);
        foreach my $o (@{$this->{_outputs}}){
          $o->{ra_sig} = $this->generateEmptySig();
        }
        my $outputNumber = @{$this->{_outputs}};
        my $closestdistance = $maxdist; #this value works out which is this closest detected object.
        my @rules;
        push @rules, $this->{_sonification}->{rules};
        foreach my $d (@{$rah_do}){
          my $detected = 0;
          my @detectedOnOutput;
          my $offCentreDistAdj = 10 * $outputNumber; #This is an adjustment to distance based on how 'in focus' an object is.
          foreach my $o (@{$this->{_outputs}}){
            if ($d->{$o->{field}}){
              $offCentreDistAdj -= 10;
              $detected++;
              push @detectedOnOutput, $o; #places reference to output in 'detected output' so it can have appropriate actions
                                          #added to its score.
            }
          }
          if ($detected >= $outputNumber && $d->{distance} < $closestdistance){
            $closestdistance = $d->{distance};
          }
          my $rh_adj = { dur => -2 + int($this->getDistanceRatio($d->{distance} + $offCentreDistAdj, $maxdist + 10, 5, 1) * 7),
                         force => int($this->getDistanceRatio($d->{distance}, $maxdist, 4, 1) * 40),
                         syp => 0,
                         offset =>0,
                         fmod => 0,
                         dvar => 0};
          $this->applyRulesToSig($d, $rh_adj, \@detectedOnOutput);
        }
        $this->setSpeedDivider($closestdistance, $maxdist);
        foreach my $o (@{$this->{_outputs}}){
          print "Writing output to $o->{path}\n";
          my $ra_sigt = $this->convertAoHtoInstrText($o->{ra_sig});
          $this->physSendInstructions($o->{path}, $ra_sigt);
        }
    }

    sub applyRulesToSig{
      # Runs through each of the rules for sonic output (these are located in a json file, which is pointed to by ns_config)
      # and applies them to the set of instructions based on the database entry detected.
      my ($this, $d, $rh_adj, $ra_doo) = @_; # d=detected entry, rh_adj=core attributes of the signal determined by distance
                                             # ra_doo=outputs that are valid for the detected entry
      #print "Applying rules, inspecting data\n";
      #$this->{_testtools}->printRefHashValues($d);
      foreach my $r (@{$this->{_rules}}){
        my $test = $r->{test};
        $test =~ s/{/\$d->{/g;
        #$test =~ s/{(.+)}/'$d->{$1}'/;
        #print "field is $1\n";
        #print "evaluating $test\n";
        my $result = eval($test);
        if ($result){
          print "Success!  $r->{action}\n";
          $rh_adj = $this->applyEffectsToAction($r, $d, $rh_adj);
          foreach my $od (@{$ra_doo}){
            print "implementing actions";
            foreach my $pos (@{$r->{positions}}){
              $this->{_audlib}->addActionToScore($r->{action},[$od->{ra_sig}, $pos, $rh_adj, $r->{arg}]);      
            }
          }
        }else{
          print "$test failed\n";
        }
      }
    }

    sub applyEffectsToAction{
        # This applies 'effects' to the sonic output by altering key variables. 
        my ($this, $r, $d, $rh_adj) = @_;
        foreach my $ek (keys %{$this->{_effects}}){
          if ($r->{applyEffects} eq $ek){
            foreach my $e (@{$this->{_effects}->{$ek}}){
              my $test = $e->{test};
              $test =~ s/\{/\$d->\{/;
              print "Evaluating $test to apply $e->{effect}\n";
              my $result = eval($test);
              if ($result){
                print "adding effect $e->{effect}\n";
                $rh_adj = $this->{_audlib}->addEffectToAction($e->{effect}, $rh_adj, $e->{arg});
              }
            }
          }else{
            print "$ek effects don't apply\n"
          }
        }
        return $rh_adj;
    }

    sub setSpeedDivider{
        my ($this, $distance, $maxdist) = @_;
        my $file = $this->{_gpoutpath} . "sig_speeddiv.o";
        my $base = 270; # was 700
        my $diffdist = $maxdist - $distance;
        my $ra_distadd = [int($base + ($diffdist * 3))]; # was * 4
        $this->physSendInstructions($file, $ra_distadd);
    }

    sub getDistanceRatio{
        my ($this, $dist, $maxdist, $curve, $invert) = @_;
        my $useDist =  $dist; 
        # lower the value in $curve, the more extreme the curve. Try 5 for curvy, 20 for straight.
        if ($invert){
            $useDist = $maxdist - $dist; 
        } 
        my $diffDistAdj = $useDist * ($useDist/$curve + ($curve*2));
        my $maxDistAdj = $maxdist * ($maxdist/$curve + ($curve*2));
        my $ratio = $diffDistAdj/$maxDistAdj;
        return $ratio;
    }

######################################## NEWNEWNEW SONIC LOGIC ##############################################
#############################################################################################################

  sub createScore{
    my ($this, $rah_do) = @_;
    print "creating score\n";
    foreach my $out (@{$this->{_outputs}}){
      $out->{ra_sig} = [];
    }

    foreach my $rh_do (@{$rah_do}){
      my $o = 0;
      foreach my $out (@{$this->{_outputs}}){
        if ($rh_do->{$out->{field}}){
          $o++;
        }
      }
      foreach my $out (@{$this->{_outputs}}){
        my $ra_instr = [];
        if ($o > 0){
          my $distthres;
          my $rh_attr = {elecount =>16, repeats=>0, solstr=>0, rhythmstr=>0};
          if ($o == 2){
            $distthres = $this->{_thres}->{_distanceBands}->{centreThresholds};
          }else{
            $distthres = $this->{_thres}->{_distanceBands}->{offcentreThresholds};
          }      
          if ($rh_do->{$out->{field}}){
            $ra_instr = $this->generateScoreColumn($rh_do, $rh_attr, $out, $distthres);
          }
        }else{
          $ra_instr = $this->generateEmptyColumn;
        }
        print "processed Instr:\n";
        print Dumper($ra_instr);
        push @{$out->{ra_sig}}, $ra_instr;
      }
    }
    $this->outputScore;
  }

  sub createEmptyScore{
    my $this = shift;
    print "creating empty score\n";
    foreach my $out (@{$this->{_outputs}}){
      $out->{ra_sig} = [];
      my $ra_instr = $this->generateEmptyColumn;
      push @{$out->{ra_sig}}, $ra_instr;
    }
    $this->outputScore; 
  }

  sub generateScoreColumn{
    my ($this, $rh_do, $rh_attr, $out, $distthres) = @_;
    print "generating Score column\n";
    my $ra_instr = [];
    #print Dumper($distthres);
    foreach my $t (@{$distthres}){
      print "$rh_do->{distance} <> $t->{maxdist}\n";
      if ($rh_do->{distance} < $t->{maxdist}){
        $rh_attr->{repeats} = $t->{repeats};
        $rh_attr->{solstr} = $t->{solstr};
      }
    }
    foreach my $b (@{$this->{_thres}->{_pcBands}}){
      my $solbonus = 0;
      if ($rh_do->{$this->{_thres}->{_pcBands}} > $b->{minval}){
        $rh_attr->{rhythmstr} = $b->{rhythmstr};
        $solbonus = $b->{solstr};
      }
      $rh_attr->{solstr} += $solbonus; 
    }
    print Dumper($rh_attr);
    if ($rh_attr->{repeats} > 0){
      my $base = $this->generateBase($rh_do->{descr});
      my $ra_rhythm = $this->processBaseIntoRhythm($base, $rh_attr->{rhythmstr});
      $ra_instr = $this->convertRhythmIntoInstr($rh_attr, $ra_rhythm);
    }else{
      print "no repeats\n";
      $ra_instr = $this->generateEmptyColumn;
    }
    print "pre returned instr:\n";
    print Dumper($ra_instr);
    return $ra_instr;
  }

  sub generateEmptyColumn{
    my $this = shift;
    my @instr = ();
    print "generating Empty Column\n";
    for(my $i=0; $i<$this->{_scorelines}; $i++){
      my $l = {line=>"d$this->{_linedur}\@f0", hasstrike=>0};
      my $ra_l = $l;
      push @instr, $ra_l;
    }
    return \@instr;
  }

  sub outputScore{
    my $this = shift;
    foreach my $out (@{$this->{_outputs}}){
      my @lines = ();
      print "Outputting to $out->{path}\n";
      #foreach my $ra (@{$ra_sig}){
      my $ra = $out->{ra_sig};
      my $sizerows = @{$ra->[0]};
      my $sizecolumns = @{$ra};
      for (my $i=0; $i<$sizerows; $i++){
        my $l = "";
        for (my $k=0; $k<$sizecolumns; $k++){
          if ($k > 0){ $l .= "|";}
          $l .= $ra->[$k]->[$i]->{line};
        }
        print "$l\n";
        push @lines, $l;
      }
      $this->physSendInstructions($out->{path}, \@lines);
    }
  }

  sub generateBase{
    my ($this, $s) = @_;
    print "generating base from: $s\n";
    my $substr = substr $s, 0, 31;
    my @char = split //, $s;
    my $size = @char;
    my @prebaserhythm;
    my @baserhythm;
    for (my $i=0; $i<32; $i+=2){
      my $cn = 0;
      if ($i < $size){
       $cn = ord($char[$i]);
      }
      print "$cn\n";
      push @prebaserhythm, $cn;
    }
    my @percentile = sort {$a <=> $b} @prebaserhythm;
    my $small = $percentile[8];
    my $medium = $percentile[11];
    my $large = $percentile[14];
    foreach my $n (@prebaserhythm){
      if ($n <= $small)    { push @baserhythm,0}
      elsif ($n <= $medium){ push @baserhythm,1}
      elsif ($n <= $large) { push @baserhythm,2}
      else                { push @baserhythm,3};
    }
    return \@baserhythm;
  }

  sub processBaseIntoRhythm{
      my ($this, $ra, $v) = @_;
      print "processing base into rhythm\n";
      my $laststate = "";
      my $lastval = 0;
      my $size = @{$ra};
      my @rhythm = ();
      my $st = $this->makeStrengthValues($v); #v must be between 0 and 4
      my $p = -1;
      for (my $i=0; $i<$size; $i++){
        if ($lastval == $st->{strongcrit} && $ra->[$i] >= $st->{strongthres} && $laststate eq "littlebeat"){
          $rhythm[$p]->{type} = "strongbeat";
          $rhythm[$p]->{ebLength} += 1;
          $laststate = "strongbeat";
        }elsif ($lastval < $st->{strongcrit} && $lastval > $st->{restcrit} &&  $ra->[$i] == 1 && $laststate eq "littlebeat"){
          $rhythm[$p]->{ebLength} += 1;
        }elsif ($ra->[$i] <= $st->{restcrit} && $laststate eq "rest"){
          $rhythm[$p]->{ebLength} += 1;
        }elsif ($ra->[$i] <= $st->{restcrit}){
          my $rh = {type => "rest", ebLength => 1};
          push @rhythm, $rh;
          $p++;
          $laststate = "rest";
        }else{
          my $rh = {type => "littlebeat", ebLength => 1};
          push @rhythm, $rh;
          $p++;
          $laststate = "littlebeat";
        }
        $lastval = $ra->[$i];
      }
      return \@rhythm;
  }

  sub makeStrengthValues{
    my ($this, $i) = @_;
    my @val = ({strongcrit=> 4, strongthres => 2, restcrit =>1},
               {strongcrit=> 3, strongthres => 2, restcrit =>1},
               {strongcrit=> 3, strongthres => 1, restcrit =>1},
               {strongcrit=> 3, strongthres => 1, restcrit =>0},
               {strongcrit=> 2, strongthres => 1, restcrit =>0});
    return $val[$i];
  }

  sub convertRhythmIntoInstr{
    print "converting rhythm into instr\n";
    my ($this, $rh, $ra_rhythm) = @_;
    my $rhylength = @{$ra_rhythm};
    my $blockdur = $this->{_sonicspace} / ($rh->{elecount} * $rh->{repeats});
    print "Blockdur is $blockdur\n";
    my @scorepart = ();
    my $curdur = 0;
    my $linesadded = 0;
    my $uf = 0;
    my $rh_attr = { blockdur=>$blockdur,
                    baseStrength=>$rh->{solstr},
                    unfinishedLine=>$uf };
    for(my $i=0;$linesadded < $this->{_scorelines}; $i++){
      if ($i == $rhylength){
        print "resetting\n";
        $i=0;
      }
      $rh_attr->{type} = $ra_rhythm->[$i]->{type};
      $rh_attr->{eleBlockLength} = $ra_rhythm->[$i]->{ebLength};
      my $ra_curBeat = $this->resolveBeat($rh_attr);
      for my $c (@{$ra_curBeat}){
        #print Dumper($c);
        if ($c->{ttldur} >= $this->{_linedur}){
          push @scorepart, $c;
          $rh_attr->{unfinishedLine} = 0;
          $linesadded++;
        }else{
          print "line unfinshed, continuing\n";
          $rh_attr->{unfinishedLine} = $c;
        }
      }
    }
    return \@scorepart;
  }
  
  sub resolveBeat{
    my ($this, $rh_attr) = @_;
    my $ra_return = [];
    switch ($rh_attr->{type}){
      case "rest"{ $ra_return = $this->addRestBlock($rh_attr)}
      case "strongbeat"{ $ra_return = $this->addStrongBeatBlocks($rh_attr)}
      case "littlebeat"{ $ra_return = $this->addLittleBeatBlocks($rh_attr)}
      case "tap"{ $ra_return = $this->addTapBlocks($rh_attr)}
    }
    return $ra_return;
  }

  sub addRestBlock{
    my ($this, $rh_attr) = @_;
    my $rah = [{dur=>$rh_attr->{blockdur} * $rh_attr->{eleBlockLength},
                force=>0}
                ];
    my $ra_return = $this->composeBlock($rh_attr, $rah);
    return $ra_return;
  }

  sub addStrongBeatBlocks{
    my ($this, $rh_attr) = @_;
    my $dur = $rh_attr->{blockdur} * $rh_attr->{eleBlockLength}; 
    my $rah = [{dur=>($dur/2)-$this->{_standardbeatdur},
                force=>0},
               {dur=>$this->{_standardbeatdur} * 2,
                force=>$rh_attr->{baseStrength}},
               {dur=>($dur/2)-$this->{_standardbeatdur},
                force=>0}
                ];
    my $ra_return = $this->composeBlock($rh_attr, $rah);
    return $ra_return;
  }
  
  sub addLittleBeatBlocks{
    my ($this, $rh_attr) = @_;
    my $dur = $rh_attr->{blockdur} * $rh_attr->{eleBlockLength}; 
    my $rah = [{dur=>($dur/2)-($this->{_standardbeatdur}/2),
                force=>0},
               {dur=>$this->{_standardbeatdur},
                force=>$rh_attr->{baseStrength}},
               {dur=>($dur/2)-($this->{_standardbeatdur}/2),
                force=>0}
                ];
    my $ra_return = $this->composeBlock($rh_attr, $rah);
    return $ra_return;
  }

  sub addTapBlocks{
    my ($this, $rh_attr) = @_;
    my $dur = $rh_attr->{blockdur};
    my $reps = $rh_attr->{eleBlockLength}; 
    my $rah = [];
    for (my $i=0; $i<$reps; $i++){
      push @{$rah}, {dur=>($dur/2)-($this->{_standardbeatdur}/2),force=>0};
      push @{$rah}, {dur=>$this->{_standardbeatdur}, force=>$rh_attr->{baseStrength}};
      push @{$rah}, {dur=>($dur/2)-($this->{_standardbeatdur}/2),force=>0};
    }
    my $ra_return = $this->composeBlock($rh_attr, $rah);
    return $ra_return;
  }

  sub composeBlock{
    my ($this, $rh_attr, $rah) = @_;
    print "adding rest block\n";
    my $ra_return;
    if ($rh_attr->{unfinishedLine}){
      $ra_return = [$rh_attr->{unfinishedLine}]
    }else{
      $ra_return = [{line => "",
                    ttldur => 0,
                    hasstrike => 0}];
    }
    my $i = 0;
    for my $rh (@{$rah}){
      print "Processing:";
      #print Dumper($rh);
      while ($rh->{dur} > 0){
        my $remains = $this->{_linedur} - $ra_return->[$i]->{ttldur};
        my $pref = "";
        if ($rh->{force} > 0){
          $ra_return->[$i]->{hasstrike} = 1;
        }
        if ($rh->{dur} > $remains){
          if (length($ra_return->[$i]->{line}) > 0){
            $pref = ",";
          }
          $ra_return->[$i]->{line} .= $pref . "d$remains\@f$rh->{force}";
          $ra_return->[$i]->{ttldur} += $remains;
          $rh->{dur} -= $remains;
          push @{$ra_return}, {line=>"", ttldur=> 0, hasstrike => 0};
          $i++;
        }else{
          if (length($ra_return->[$i]->{line}) > 0){
            $pref = ",";
          }
          $ra_return->[$i]->{line} .= $pref . "d$rh->{dur}\@f$rh->{force}";
          $ra_return->[$i]->{ttldur} += $rh->{dur};
          $rh->{dur} = 0;
        }
      }
    }
    return $ra_return;
  }

}
1;



