import mag3110
import time

path = "/home/pi/nsdata/gpio/"
compass = mag3110.compass()
#compass.calibrate()
compass.loadCalibration()
c = 0
filestocheck = 2
state = 1
waitct = 0
waitmax = 6

def checkMagState():
    rtn = False
    for i in range(1, filestocheck):
        try:
            s = open(path + "mag" + str(i) + ".s", "r")  
            t = s.read()
            if t == "1":
                rtn = True
            s.close()
        except:
            print "no mag file " + str(i)
    return rtn 
while True:
    f = open(path + '0.c', 'w')
    print >> f, str(c) 
    f.close()
    for i in range(0,1000):
        f = open(path + '0.c', 'a')
        try:
            mag = checkMagState()
            if mag == False:
                if state == 1:
                    c = compass.getCompenstatedBearing()
                    print >> f, str(c)
                else:
                    if waitct >= waitmax:
                        state = 1
                    waitct += 1
            else:
                state = 0
                waitct = 0
        except:
            print "Error getting compass"
            time.sleep(1)
        time.sleep(0.05)
        f.close()
