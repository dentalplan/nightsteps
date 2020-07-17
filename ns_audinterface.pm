package ns_audinterface{
#the audio interface layer translates data structures into audio parameters;
    use strict;
    use warnings;
    use lib ".";
    use Switch;
    use ns_testtools;
    use ns_audlibrary;
    use Math::Round qw(round);

    sub new {
        my ($class, $son, $option) = @_;
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
            _sonification => $son,
            _rules => $ra_rules,
            _effects=> $rh_effects,
            _testtools => ns_testtools->new,
            _audlib => ns_audlibrary->new,
            _outputs => [{path=>'/home/pi/nsdata/gpio/sig_l.o', field=>'detected_left', ra_sig=>[]}, 
                         {path=>'/home/pi/nsdata/gpio/sig_r.o', field=>'detected_right', ra_sig=>[]}],
            _gpoutpath => '/home/pi/nsdata/gpio/'
        };
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
}
1;



