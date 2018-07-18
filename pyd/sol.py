from gpiozero import DigitalOutputDevice
import os
import time
import re
from collections import deque

sol = [DigitalOutputDevice(5), DigitalOutputDevice(6)]
state = [0,0]
filepath = ["/home/pi/nsdata/gpio/sol-l.o", "/home/pi/nsdata/gpio/sol-r.o"]
instruction = [deque(['s']), deque(['s'])]
for instr in instruction:
    instr.clear()

def getInstrFromFile(fileName):

    with open(fileName) as f:
        lines = deque (f.read().splitlines())
        print "lines read\n"
        return lines

def processInstr(newInstr, instr):
  
    mode = 'q'
    while (len(newInstr) > 0):
        ni = newInstr.popleft()
        ni.rstrip()
        if (ni == 'q' or ni == 'i'):
            mode = ni
            print "found q"
        elif (ni == 't'):
            instr.clear()
            mode = 'q'
        elif (mode == 'q'):
            instr.append(ni)
            print "appended\n"
        elif (mode == 'i'):
            instr.appendleft(ni)            
    return instr

while True:

    for i in range(0,len(instruction)):
#        print "working with " + str(i)
        if (os.path.exists(filepath[i])):
            newInstr = getInstrFromFile(filepath[i])
            os.remove(filepath[i])
            instruction[i] = processInstr(newInstr, instruction[i])

        if (len(instruction[i]) > 0): 
            mi = instruction[i].popleft()
            matchObjHigh = re.match(r'h(\d+)', mi, re.M|re.I)
            matchObjLow = re.match(r'l(\d+)', mi, re.M|re.I)
            if (matchObjHigh):
 #               print "matched high"
                if (state[i] == 0):
                    state[i] = 1
                    sol[i].on()
                    print str(i) + " on\n"
                millis = int(matchObjHigh.group(1)) - 1
                if (millis > 0):
                    ni = 'h' + str(millis)
                    instruction[i].appendleft(ni)
            if (matchObjLow):
  #              print "matched low"
                if (state[i] == 1):
                    state[i] = 0
                    sol[i].off()
                    print str(i) + "off\n"
                millis = int(matchObjLow.group(1)) - 1
                if (millis > 0):
                    ni = 'l' + str(millis)
                    instruction[i].appendleft(ni)

    time.sleep(0.001)

#    if (state == 0):
#        state = 1
#        sol.on()
#        sleep(0.2)
#    else:
#        state = 0
#        sol.off()
#        sleep(2)
    
