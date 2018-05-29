import mag3110
import time

path = "/home/pi/nsdata/gpio/"
compass = mag3110.compass()
#compass.calibrate()
compass.loadCalibration()
f = open(path + '0.c', 'w')
while True:
    c = compass.getBearing()
    print >> f, str(c) + "\n"
    time.sleep(0.01)
