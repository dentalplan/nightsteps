// FM synthesis by hand

1400::ms => dur len;

0 => int objects;

SinOsc w;
200 => w.freq;
0::ms => dur past;
900::ms => dur start;

// time-loop
while( past < len )
{
    if(start < past){
        w => dac;
    }
    // advance time by 1 samp
    10::ms => now;
    10::ms +=> past;
}
