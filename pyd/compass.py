import mag3110

path = "/home/pi/nsdata/gpio/"
compass = mag3110.compass()
#compass.calibrate()
compass.loadCalibration()
f = open(path + '0.c', 'w')
while True:
    c = compass.getBearing()
    print >> f, c + "\n"
    time.sleep(0.01)
