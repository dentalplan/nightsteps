import mag3110

compass = mag3110.compass()
#compass.calibrate()
compass.loadCalibration()
#while True:
print compass.getBearing()
