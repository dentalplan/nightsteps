package ns_audinterface{
#the audio interface layer translates data structures into audio parameters;
    use strict;
    use warnings;
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
                    push @lines1, "h$h";
                    push @lines1, "l$l";
                }
            }else{
                my $t = ($h + $l) * $rep;
                push @lines1, "l$t";
            }
            if ($rah_do->[$i]->{l}){
                for (my $k=0; $k<$rep;$k++){
                    push @lines2, "h$h";
                    push @lines2, "l$l";
                }
            }else{
                my $t = ($h + $l) * $rep;
                push @lines2, "l$t";
            }
            push @lines1, "l200";
            push @lines2, "l200";
        }
        push @lines1, "l500";
        push @lines2, "l500";
        $this->physSendInstructions($this->{_gpoutpath} . "dig1.o", \@lines1);
        $this->physSendInstructions($this->{_gpoutpath} . "dig2.o", \@lines2);
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

}
1;


