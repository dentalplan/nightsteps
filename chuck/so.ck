// FM synthesis by hand

100 => float gmult;
8 => float gbase;

2000 => int lenms;
lenms::ms => dur len;

0 => int objects;

Std.atoi(me.arg(0)) => objects;

SinOsc o1[objects];
SinOsc o2[objects];
dur t[objects];
dur s[objects];
float lr[objects];
float g[objects];

if(me.args()){
    for(0 => int i; i < objects; i++){
        (i * 5) => int p;
        Std.atof(me.arg(p+1)) => lr[i];                     // set panning
        Std.atof(me.arg(p+2)) => float timefract;           // set timing
        (Std.atof(me.arg(p+3)) * gmult) + gbase => g[i];    //
        Std.atof(me.arg(p+4)) => float freq;
        Std.atoi(me.arg(p+5))::ms => s[i];
        Std.ftoi(timefract * lenms) => int timepoint;
        timepoint::ms => t[i];
        SinOsc lo;
        freq => lo.freq;
        <<< g[i] >>>;
        <<< freq >>>;
        lo => o1[i];
        lo => o2[i];
    }
}else{
    <<< "No args!" >>>;
}

Noise n => dac;
0.01 => n.gain;
0::ms => dur past;

// time-loop
while( past < len )
{
    
    for(0 => int i; i< objects; i++){
        if(((t[i] - past) < s[i]) && (past < t[i])){
            1 - lr[i] => float rl;
            g[i] * rl => o1[i].gain;
            g[i] * lr[i] => o2[i].gain;
            0 => o2[i].gain;
            o1[i] => dac.left;
            o2[i] => dac.right;
        }else if(t[i] > past){
             
        }
        else{
            0 => o1[i].gain;
            0 => o2[i].gain;
        }
    }
    // advance time by 1 samp
    10::ms => now;
    10::ms +=> past;
}
