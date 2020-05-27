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

    sub digWaitOnGPS{
         
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


    sub resetSonicSig{
        my $this = shift;
        foreach my $o (@{$this->{_outputs}}){
          my $ra = $this->generateEmptySig();
          my $rat = $this->convertAoHtoInstrText($ra);
          $this->physSendInstructions($o->{path}, $rat);
        }
    }

    sub sonicSig{
        my ($this, $maxdist, $rah_do) = @_;
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
              push @detectedOnOutput, $o;
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
          my $numberOfRules = @{$this->{_rules}};
          print $numberOfRules;
          foreach my $r (@{$this->{_rules}}){
            my $test = $r->{test};
            $test =~ s/{/\$d->{/;
            print "evaluating $test\n";
            my $result = eval($test);
            if ($result){
              print "Success!  $r->{action}\n";
              $rh_adj = $this->applyEffectsToAction($r, $d, $rh_adj);
              foreach my $od (@detectedOnOutput){
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
        $this->setSpeedDivider($closestdistance, $maxdist);
        foreach my $o (@{$this->{_outputs}}){
          print "Writing output to $o->{path}\n";
          my $ra_sigt = $this->convertAoHtoInstrText($o->{ra_sig});
          $this->physSendInstructions($o->{path}, $ra_sigt);
        }
    }

    sub applyEffectsToAction{
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

    sub LDDBsonicSig{
        my ($this, $maxdist, $maxyear, $rah_do) = @_;
        my $size = @{$rah_do};
        # these arrays will be written into the sig_l and sig_r files to be picked
        # up by the noisemakers
        my $ral = $this->generateEmptySig(21);
        my $rar = $this->generateEmptySig(21);
        my $closestdistance = $maxdist;
        for (my $i=0; $i<$size; $i++){
            my @arrset;
            my $offCentreDistAdd = 20;
            # we only need to adjustments to for applications that are detected.
            if ($rah_do->[$i]->{detected_left}){
                push @arrset, $ral;
                $offCentreDistAdd -= 10; 
            }
            if ($rah_do->[$i]->{detected_right}){
                push @arrset, $rar;
                $offCentreDistAdd -= 10; 
            }
            if ($rah_do->[$i]->{detected_left} && $rah_do->[$i]->{detected_right} && $rah_do->[$i]->{distance} < $closestdistance){
                $closestdistance = $rah_do->[$i]->{distance};
            }
            #one way the device indicates distance is by blanking out elements of the signal until you are
            # close enough
            my $cap = 16 - int($this->getDistanceRatio($rah_do->[$i]->{distance}, $maxdist, 10, 0) * 16);
            # Another is to increase the duration and force of the strike
            my $da = -2 + int($this->getDistanceRatio($rah_do->[$i]->{distance} + $offCentreDistAdd, $maxdist + 10, 5, 1) * 7);
            my $df = int($this->getDistanceRatio($rah_do->[$i]->{distance}, $maxdist, 4, 1) * 40);
            for (my $k=0; $k<$cap; $k++){
                my $rh_beat = $this->makeBeatData($rah_do->[$i], $k, $da, $df, $maxyear);
                foreach my $ra (@arrset){
                   $ra->[$rh_beat->{pos}]->{dur} += $rh_beat->{in};
                   if ($rh_beat->{force} > 0 && $ra->[$rh_beat->{pos}]->{force} == 0){
                       $ra->[$rh_beat->{pos}]->{force} += 45 + $rh_beat->{force};
                   }else{
                       $ra->[$rh_beat->{pos}]->{force} += $rh_beat->{force};
                   }
                }
            }
            foreach my $ra (@arrset){
                $this->makeBeatId($rah_do->[$i]->{permission_id}, $ra);
            }
        }
        my $filel = $this->{_gpoutpath} . "sig_l.o";
        my $filer = $this->{_gpoutpath} . "sig_r.o";
        my $ralt = $this->convertAoHtoInstrText($ral);
        my $rart = $this->convertAoHtoInstrText($rar);
        $this->setSpeedDivider($closestdistance, $maxdist);
        $this->physSendInstructions($filel, $ralt);
        $this->physSendInstructions($filer, $rart);
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

    sub makeBeatId{
        my ($this, $id, $ra) = @_;
        my @number = split( //,$id);
        my $size = @number;
        for (my $i=0; $i<($size-1); $i++){
            #print "number $number[$i]\n";
            my $pos = $number[$i] + $number[$i+1];
            #print "Examing position $pos\n";
            if ($ra->[$pos]->{dur} > 0){
                #print "Adding to $pos";
                $ra->[$pos]->{dur}++;
                $ra->[$pos]->{force}++;
            }
        }
    }
    
    sub makeBeatData{
        my ($this, $rh, $i, $da, $df, $maxyear) = @_;
        my $rtn;
        #print "Setting up distance-dur: $da, distance-force: $df\n";
        switch($i){
            case 0  {   #permission date beat 
                      my $pos = 15;
                      if ($rh->{permissionyear} > ($maxyear - 5)){
                          my $pos = 3;
                      }elsif ($rh->{permissionyear} > ($maxyear - 10)){
                          my $pos = 9;
                      }
                      $rtn = {pos=>$pos, in=>11 + $da, force=>$df};
                  }
            case 1  {   #not yet completed beat 1
                        $rtn = {pos=>7, in=>0, force=>0};
                        if ($rh->{status_rc} eq "STARTED" || $rh->{status_rc} eq "SUBMITTED" || $rh->{status_rc} eq "PENDING"){
                            $rtn->{in} = 11 + $da;
                            $rtn->{force} = $df;
                        }
                    }
            case 2  {   #standard distance beat
                        $rtn = {pos=>19, in=>7 + $da, force=>$df};
                    }
            case 3  {   #completed beat 1
                        $rtn = {pos=>18, in=>0, force=>0};
                        if ($rh->{status_rc} eq "COMPLETED"){
                            $rtn->{in} = 9 + $da;
                            $rtn->{force} = $df;
                        }
                    }
            case 4  {   #when completed beat
                        my $pos = 17;
                        my $in = 0;
                        my $force = 0;
                        if ($rh->{status_rc} eq "COMPLETED"){
                            $in = 9 + $da;
                            $force = $df;
                            if ($rh->{completedyear} > ($maxyear - 5)){
                                my $pos = 5;
                            }elsif ($rh->{completedyear} > ($maxyear - 10)){
                                my $pos = 11;
                            }
                        }
                        $rtn = {pos=>$pos, in=>$in, force=>$df};
                    }
            case 5  {   #standard distance beat
                        $rtn = {pos=>16, in=>7 + $da, force=>$df};
                    }
            case 6  {   #residential units beat 1
                        $rtn = {pos=>10, in=>0, force=>0};
                        if ($rh->{exist_res_units_yn} eq "Y"){
                            $rtn->{in} = 5 + $da;
                            $rtn->{force} = $df;
                        }
                    }
            case 7  {   #non-res use beat 1
                        $rtn = {pos=>13, in=>0, force=>$df};
                        if ($rh->{exist_non_res_use_yn} eq "Y"){
                            $rtn->{in} = 5 + $da;
                            $rtn->{force} = $df;
                        }
                    }
            case 8  {   #standard distance beat
                        $rtn = {pos=>12, in=>7 + $da, force => $df}
                    }
            case 9  {   #residential units beat 1 
                        $rtn = {pos=>1, in=>0, force=>0};
                        if ($rh->{proposed_res_units_yn} eq "Y"){
                            $rtn->{in} = 5 + $da;
                            $rtn->{force} = $df;
                        }
                    }
            case 10  {  #non-res use beat 2
                        $rtn = {pos=>6, in=>0, force=>0};
                        if ($rh->{proposed_non_res_use_yn} eq "Y"){
                            $rtn->{in} = 5 + $da;
                            $rtn->{force} = $df;
                        }
                     }
            case 11  {  #standard distance beat
                        $rtn = {pos=>8, in=>7 + $da, force=>$df}
                     }
            case 12  {
                        $rtn = {pos=>2, in=>0, force=>0};
                        if ($rh->{status_rc} eq "STARTED" || $rh->{status_rc} eq "SUBMITTED"){
                            $rtn->{in} = 11 + $da;
                            $rtn->{force} = $df;
                        }
                     }
            case 13  {  $rtn = {pos=>4, in=>7 + $da, force=>$df} }
            case 14  {
                        $rtn = {pos=>14, in=>0, force=>$df};
                        if ($rh->{status_rc} eq "COMPLETED"){
                            $rtn->{in} = 9 + $da;
                            $rtn->{force} = $df;
                        }
                     }
            case 15  {  $rtn = {pos=>0, in=>7 + $da, force=>$df} }
        }
        return $rtn
    }
}
1;



