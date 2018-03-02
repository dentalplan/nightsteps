package ns_chuckout
{
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my $this  = {
#            _type => shift,
#            _soundcard => '--dac3',
            _soundcard => '',
        };
        bless $this, $class;
        return $this;
    }

    sub basicOut{
        my $this = shift;
        my $rah_so = shift;
        my $size = @{$rah_so};
        my $ckline = ":$size";
        for my $rh (@{$rah_so}){
            $ckline .= ":" . $rh->{panning};
            $ckline .= ":" . $rh->{starttime};
            $ckline .= ":" . $rh->{gain};
            $ckline .= ":" . $rh->{freq};
            $ckline .= ":" . $rh->{dur};
        }
        system "chuck $this->{_soundcard} chuck/so$ckline";
    }

}
1;
