import mag3110
import time

path = "/home/pi/nsdata/gpio/"
compass = mag3110.compass()
#compass.calibrate()
compass.loadCalibration()
f = open(path + '0.c', 'w')
while True:
    try:
        c = compass.getBearing()
    except:
        print "Error getting compass"
    print >> f, str(c) 
    time.sleep(0.01)
