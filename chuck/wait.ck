// FM synthesis by hand

1400::ms => dur len;

0 => int objects;

SinOsc w;
200 => w.freq;
0.5 => w.gain;
0::ms => dur past;
900::ms => dur start;

// time-loop
while( past < len )
{
    if(start < past){
        w => dac;
    }
    // advance time by 1 samp
    100::ms => now;
    100::ms +=> past;
}
