import mag3110
import time

path = "/home/pi/nsdata/gpio/"
compass = mag3110.compass()
#compass.calibrate()
compass.loadCalibration()
c = 0
while True:
    f = open(path + '0.c', 'w')
    print >> f, str(c) 
    for i in range(0,1000):
        try:
            c = compass.getBearing()
        except:
            print "Error getting compass"
        print >> f, str(c) 
        time.sleep(0.01)
