import time
# Import SPI library (for hardware SPI) and MCP3008 library.
import Adafruit_GPIO.SPI as SPI
import Adafruit_MCP3008

# Hardware SPI configuration:
SPI_PORT   = 0
SPI_DEVICE = 0
mcp = Adafruit_MCP3008.MCP3008(spi=SPI.SpiDev(SPI_PORT, SPI_DEVICE))

filelist = []
a = [0,0,0,0,0,0,0,0]
path = "/home/pi/nsdata/gpio/"
for i in range(0,8):
    filelist.append(open(path + str(i) + ".a", "w"))

while True:

    # Set up output files
    for c in range(0,1000):
        for i in range(0,8):
            a[i] = mcp.read_adc(i)
            value = '{num:04d}'.format(num=a)
            filelist[i].write(str(value) + "\n")
            time.sleep(0.01)

    for i in range(0,8):
        filelist.append(open(path + str(i) + ".a", "w"))
        filelist[i].write(str(value) + "\n")
