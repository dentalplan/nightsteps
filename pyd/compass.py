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
    f.close()
    for i in range(0,1000):
        f = open(path + '0.c', 'a')
        try:
            c = compass.getBearing()
        except:
            print "Error getting compass"
            time.sleep(1)
        print >> f, str(c) 
        time.sleep(0.01)
        f.close()
