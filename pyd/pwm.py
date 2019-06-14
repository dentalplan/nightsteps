from gpiozero import PWMOutputDevice
import os
import time
import re
from collections import deque

#########################################################################
# instruction | behaviour                                               #
#-------------|---------------------------------------------------------#
#  o          | Set output to val for number of miliseconds (e.g o10-500)  #
#  q          | Append following instructions to end of queue           #
#  t          | Reset the queue, and go straight to the new instructions#
#  i          | Add following instructions to beginning of queue        #
#-----------------------------------------------------------------------#
#########################################################################
pwm = [PWMOutputDevice(12), PWMOutputDevice(13)]
state = [0,0]
#look in the following files for instructions
filepath = ["/home/pi/nsdata/gpio/pwm1.o", "/home/pi/nsdata/gpio/pwm2.o"]
#make two double ended queues for instructions
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

##main loop
while True:

    for i in range(0,len(instruction)):
#        print "working with " + str(i)
        if (os.path.exists(filepath[i])):
            newInstr = getInstrFromFile(filepath[i])
            os.remove(filepath[i])
            instruction[i] = processInstr(newInstr, instruction[i])

        if (len(instruction[i]) > 0): 
            mi = instruction[i].popleft()
            matchObjSetVal = re.match(r'o(\d+)-(\d+)', mi, re.M|re.I)
            if (matchObjSetVal):
 #               print "matched high"
                valint = int(matchObjSetVal.group(1))
                valfl = float(valint) / 10
                print "setting pwm to " + str(valfl)
                pwm[i].value = valfl      
                millis = int(matchObjSetVal.group(2)) - 1
                if (millis > 0):
                    ni = 'o' + str(valint) + "-" + str(millis)
                    instruction[i].appendleft(ni)

    time.sleep(0.001)

