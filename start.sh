#! /bin/bash

echo "yo planet!"

ck1=$(ps aux | grep /home/pi/nsdata/metagps.pl | grep -v grep | wc -l)
echo $ck1
if [ $ck1 -eq 0 ]
then
    echo 'init metagps.pl'
    perl /home/pi/nsdata/metagps.pl &
fi

ck3=$(ps aux | grep  /home/pi/nightsteps/pyd/gpio-a-all.py | grep -v grep | wc -l)
echo $ck3
if [ $ck3 -eq 0 ]
then
    echo 'init gpio-a'
    python /home/pi/nightsteps/pyd/gpio-a-all.py &
fi

ck4=$(ps aux | grep /home/pi/nightsteps/pyd/compass.py | grep -v grep | wc -l)
echo $ck3
if [ $ck4 -eq 0 ]
then
    echo 'init compass'
    python /home/pi/nightsteps/pyd/compass.py &
fi

ck2=$(ps aux | grep /home/pi/nightsteps/nightsteps_run.pl | grep -v grep | wc -l)
echo $ck2
if [ $ck2 -eq 0 ]
then
    echo 'init nightsteps'
    perl /home/pi/nightsteps/nightsteps_run.pl>nslog.txt &
fi

echo "all done"
