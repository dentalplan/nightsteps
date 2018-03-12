// FM synthesis by hand
1000::ms => dur len;
450 => float ele;
0.5 => float bal;
if( me.args() )
{
    Std.atoi(me.arg(0))::ms => len;
        Std.atof(me.arg(1)) => ele;
    Std.atof(me.arg(2)) => bal;
}
<<< len >>>;
<<< ele >>>;
<<< bal >>>;
// carrier
SinOsc c1 => dac.left;
SinOsc c2 => dac.right;
// modulator
SinOsc m => blackhole;

bal => c1.gain;
bal => c2.gain;

// carrier frequency
220 => float cf;
// modulator frequency
ele => float mf => m.freq;
// index of modulation
100 => float index;

0::ms => dur past;

// time-loop
while( past < len )
{
    // modulate
    cf + (index * m.last()) => c1.freq;
    cf + (index * m.last()) => c2.freq;
    // advance time by 1 samp
    1::samp => now;
    1::samp +=> past;
}
~                                                                                                                                                                                     
~                               
