import time
import os
# Import SPI library (for hardware SPI) and MCP3008 library.
import Adafruit_GPIO.SPI as SPI
import Adafruit_MCP3008

# Hardware SPI configuration:
SPI_PORT   = 0
SPI_DEVICE = 0
mcp = Adafruit_MCP3008.MCP3008(spi=SPI.SpiDev(SPI_PORT, SPI_DEVICE))

a = [0,0,0,0,0,0,0,0]
path = "/home/pi/nsdata/gpio/"
#print >> f, "fucking work dman you"
while True:

    line = ""
    # Set up output files
    for c in range(0,1000):
        line = ""
        f = open(path + "a.a", "a")
        for i in range(0,8):
            a[i] = mcp.read_adc(i)
            value = '{num:04d}'.format(num=a[i])
            line += str(value) + "-"
        print >> f, line
#        print line
        f.close()
#        print "csy"
#        localtime = time.asctime(time.localtime(time.time()))
#        print "written " + line + " to a.a at " + localtime
        time.sleep(0.1)
    time.sleep(0.05)
    f = open(path + "a.a", "w")
    print >> f, line
    f.close()
