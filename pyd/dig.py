from gpiozero import DigitalOutputDevice
import os
import time
import re
from collections import deque

#########################################################################
# instruction | behaviour                                               #
#-------------|---------------------------------------------------------#
#  l          | Set output to low for number of miliseconds (e.g l500)  #
#  h          | Set output to high for number of miliseconds (e.g. h200)#
#  q          | Append following instructions to end of queue           #
#  t          | Reset the queue, and go straight to the new instructions#
#  i          | Add following instructions to beginning of queue        #
#-----------------------------------------------------------------------#
#########################################################################

digOut = [DigitalOutputDevice(5), DigitalOutputDevice(6), DigitalOutputDevice(17)]
state = [0,0,0]
#look in the following files for instructions
filepath = ["/home/pi/nsdata/gpio/dig1.o", "/home/pi/nsdata/gpio/dig2.o", "/home/pi/nsdata/gpio/dig3.o"]
#make two double ended queues for instructions, one for eeach of the digital outs
queuedInstruction = [deque(['s']), deque(['s']), deque(['s'])]
activeInstruction = [deque(['s']), deque(['s']), deque(['s'])]
for instr in activeInstruction:
    instr.clear()
for instr in queuedInstruction:
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
#            print "found q"
        elif (ni == 't'):
            instr.clear()
            mode = 'q'
        elif (mode == 'q'):
            instr.append(ni)
#            print "appended\n"
        elif (mode == 'i'):
            instr.appendleft(ni)            
    return instr

##main loop
while True:

    # Cycle through the two instruction sets.
    for i in range(0,len(activeInstruction)):
#        print "working with " + str(i)

        if (len(activeInstruction[i]) > 0):
            l = len(activeInstruction[i])
  #          print "We have " + str(l) + " instructions \n" 
            mi = activeInstruction[i].popleft()
            matchObjHigh = re.match(r'h(\d+)', mi, re.M|re.I)
            matchObjLow = re.match(r'l(\d+)', mi, re.M|re.I)
            if (matchObjHigh):
 #               print "matched high"
                if (state[i] == 0):
                    state[i] = 1
                    digOut[i].on()
                    print str(i) + " on\n"
                millis = int(matchObjHigh.group(1)) - 1
                if (millis > 0):
                    ni = 'h' + str(millis)
                    activeInstruction[i].appendleft(ni)
            if (matchObjLow):
  #              print "matched low"
                if (state[i] == 1):
                    state[i] = 0
                    digOut[i].off()
                    print str(i) + "off\n"
                millis = int(matchObjLow.group(1)) - 1
                if (millis > 0):
                    ni = 'l' + str(millis)
                    activeInstruction[i].appendleft(ni)
        elif (os.path.exists(filepath[i])):
                newInstr = getInstrFromFile(filepath[i])
#                print "removing file\n"
                os.remove(filepath[i])
                activeInstruction[i] = processInstr(newInstr, activeInstruction[i])
    time.sleep(0.001)

#    if (state == 0):
#        state = 1
#        sol.on()
#        sleep(0.2)
#    else:
#        state = 0
#        sol.off()
#        sleep(2)
    
