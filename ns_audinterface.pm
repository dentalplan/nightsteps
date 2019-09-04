package ns_audinterface{
#the audio interface layer translates data structures into audio parameters;
    use strict;
    use warnings;
    use lib ".";
    use Switch;
    use ns_testtools;
    use Math::Round qw(round);

    sub new {
        my $class = shift;
        my $this  = {
            _mode => shift,
            _testtools => ns_testtools->new,
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

    sub resetSonicSig{
        my $this = shift;
        my $ral = [0,0,0,0,0,0,0,0,0,0,
                   0,0,0,0,0,0,0,0,0,0,
                   0];
        my $rar = [0,0,0,0,0,0,0,0,0,0,
                   0,0,0,0,0,0,0,0,0,0,
                   0];
        my $filel = $this->{_gpoutpath} . "sig_l.o";
        my $filer = $this->{_gpoutpath} . "sig_r.o";
        $this->physSendInstructions($filel, $ral);
        $this->physSendInstructions($filer, $rar);
    }

    sub LDDBsonicSig{
        my ($this, $maxdist, $maxyear, $rah_do) = @_;
        my $size = @{$rah_do};
        my $ral = [0,0,0,0,0,0,0,0,0,0,
                   0,0,0,0,0,0,0,0,0,0,
                   0];
        my $rar = [0,0,0,0,0,0,0,0,0,0,
                   0,0,0,0,0,0,0,0,0,0,
                   0];
        for (my $i=0; $i<$size; $i++){
            my @arrset;
            if ($rah_do->[$i]->{detected_left}){
                push @arrset, $ral;
            }
            if ($rah_do->[$i]->{detected_right}){
                push @arrset, $rar;
            }
            my $cap = 16 - int(($rah_do->[$i]->{distance}/$maxdist) * 16);
            my $da = int(($rah_do->[$i]->{distance}/$maxdist) * 5);
            for (my $k=0; $k<$cap; $k++){
                my $rh_beat = $this->makeBeatData($rah_do->[$i], $k, $da, $maxyear);
                foreach my $ra (@arrset){
                   $ra->[$rh_beat->{pos}] += $rh_beat->{in};
                }
            }
            foreach my $ra (@arrset){
                $this->makeBeatId($rah_do->[$i]->{permission_id}, $ra);
            }
        }
        my $filel = $this->{_gpoutpath} . "sig_l.o";
        my $filer = $this->{_gpoutpath} . "sig_r.o";
        $this->physSendInstructions($filel, $ral);
        $this->physSendInstructions($filer, $rar);
    }

    sub makeBeatId{
        my ($this, $id, $ra) = @_;
        my @number = split( //,$id);
        my $size = @number;
        for (my $i=0; $i<($size-1); $i++){
            print "number $number[$i]\n";
            my $pos = $number[$i] + $number[$i+1];
            print "Examing position $pos\n";
            if ($ra->[$pos] > 0){
                print "Adding to $pos";
                $ra->[$pos]++;
            }
        }
    }
    
    sub makeBeatData{
        my ($this, $rh, $i, $da, $maxyear) = @_;
        my $rtn;
        switch($i){
            case 0  {   #permission date beat 
                      my $pos = 15;
                      if ($rh->{permissionyear} > ($maxyear - 5)){
                          my $pos = 3;
                      }elsif ($rh->{permissionyear} > ($maxyear - 10)){
                          my $pos = 9;
                      }
                      $rtn = {pos=>$pos, in=>11 + $da};
                  }
            case 1  {   #not yet completed beat 1
                        $rtn = {pos=>7, in=>0};
                        if ($rh->{status_rc} eq "STARTED" || $rh->{status_rc} eq "SUBMITTED" || $rh->{status_rc} eq "PENDING"){
                            $rtn->{in} = 11 + $da;
                        }
                    }
            case 2  {
                        $rtn = {pos=>19, in=>7 + $da};
                    }
            case 3  {
                        $rtn = {pos=>18, in=>0};
                        if ($rh->{status_rc} eq "COMPLETED"){
                            $rtn->{in} = 9 + $da;
                        }
                    }
            case 4  {
                        my $pos = 17;
                        my $in = 0;
                        if ($rh->{status_rc} eq "COMPLETED"){
                            $in = 9 + $da;
                            if ($rh->{completedyear} > ($maxyear - 5)){
                                my $pos = 5;
                            }elsif ($rh->{completedyear} > ($maxyear - 10)){
                                my $pos = 11;
                            }
                        }
                        $rtn = {pos=>$pos, in=>$in};
                    }
            case 5  {
                        $rtn = {pos=>16, in=>7 + $da};
                    }
            case 6  {
                        $rtn = {pos=>10, in=>0};
                        if ($rh->{exist_res_units_yn} eq "Y"){
                            $rtn->{in} = 5 + $da;
                        }
                    }
            case 7  {
                        $rtn = {pos=>13, in=>0};
                        if ($rh->{exist_non_res_use_yn} eq "Y"){
                            $rtn->{in} = 5 + $da;
                        }
                    }
            case 8  {
                        $rtn = {pos=>12, in=>7 + $da}
                    }
            case 9  {
                        $rtn = {pos=>1, in=>0};
                        if ($rh->{proposed_res_units_yn} eq "Y"){
                            $rtn->{in} = 5 + $da;
                        }
                    }
            case 10  {
                        $rtn = {pos=>6, in=>0};
                        if ($rh->{proposed_non_res_use_yn} eq "Y"){
                            $rtn->{in} = 5 + $da;
                        }
                     }
            case 11  {
                        $rtn = {pos=>8, in=>7 + $da}
                     }
            case 12  {
                        $rtn = {pos=>2, in=>0};
                        if ($rh->{status_rc} eq "STARTED" || $rh->{status_rc} eq "SUBMITTED"){
                            $rtn->{in} = 11 + $da;
                        }
                     }
            case 13  {  $rtn = {pos=>4, in=>7 + $da} }
            case 14  {
                        $rtn = {pos=>14, in=>0};
                        if ($rh->{status_rc} eq "COMPLETED"){
                            $rtn->{in} = 9 + $da;
                        }
                     }
            case 15  {  $rtn = {pos=>0, in=>7 + $da} }
        }
        return $rtn
    }
}
1;



