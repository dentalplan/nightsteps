from gpiozero import PWMOutputDevice
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
#  t          | Add following instructions to beginning of queue        #
#-----------------------------------------------------------------------#
#########################################################################

#digOut = [DigitalOutputDevice(5), DigitalOutputDevice(6)]
pwm = [PWMOutputDevice(12), PWMOutputDevice(13)]
state = [0,0,0]
beat = float(70)
baseSpeedDiv = float(700)
speedDivider = baseSpeedDiv 
tempo = beat/speedDivider
magnetic = [True,True,False]
compassPaused = False
#look in the following files for instructions
speedDivPath = "/home/pi/nsdata/gpio/sig_speeddiv.o"
filepath = ["/home/pi/nsdata/gpio/sig_r.o", "/home/pi/nsdata/gpio/sig_l.o"] #, "/home/pi/nsdata/gpio/sig_i.o"]
statepath = ["/home/pi/nsdata/gpio/mag1.s", "/home/pi/nsdata/gpio/mag2.s"] #, "/home/pi/nsdata/gpio/mag3.s"]
#make two double ended queues for instructions, one for eeach of the digital outs
#queuedInstruction = [deque(['s']), deque(['s']), deque(['s'])]
activeInstruction = [deque(['s']), deque(['s'])]#, deque(['s'])]
for sp in statepath:
    with open(sp, "w") as s:
        s.write("0")
        s.close()
for instr in activeInstruction:
    instr.clear()

def getInstrFromFile(fileName):
    with open(fileName) as f:
        lines = deque (f.read().splitlines())
#        print "lines read\n"
        return lines

def getSpeedDivFromFile(fileName):
    with open(fileName) as f:
        line = f.read()
        if (line > baseSpeedDiv): 
            return float(line)
        else:
            return baseSpeedDiv

i = 0
instrSize = [20,20]
while True:
    # Cycle through  two instruction sets.
#        print "now on " + str(i)       
#    print "i is " + str(i) 
    speedDivider = getSpeedDivFromFile(speedDivPath)
    tempo = beat/speedDivider
    for f in range(0, len(filepath)):
        activeInstruction[f] = getInstrFromFile(filepath[f])
        instrSize[f] = len(activeInstruction[f])
#        print "Instr Size " + str(f) + " is " +  str(instrSize[f])
        if instrSize[f] > 0:
#            print "File " + str(f) + " of " + str(len(filepath)) + "; instr " + str(i) + " of " + str(instrSize[f])
            activeInstruction[f][i] = float(activeInstruction[f][i])
            if activeInstruction[f][i] > ((beat/5.0) * 3.0):
#                print "instr too high"
                activeInstruction[f][i] = (beat/5.0) * 3.0
    
    t = tempo
    #print tempo
    while (t > 0.0):
#            print t
        for f in range(0, len(filepath)):
            if i < instrSize[f]:
                o = activeInstruction[f][i]/speedDivider
                #print o
                if t > (tempo - o) and (state[f] == 0):
                        state[f] = 1.0
                        if magnetic[f] and compassPaused == False:
                            compassPaused = True
                            with open(statepath[f], "w") as s:
                                s.write("1")
                                s.close()
                        pwm[f].value = 1
                        #print str(f) + " ON\n"
                elif t <= (tempo - o) and (state[f] == 1):
                        state[f] = 0
                        pwm[f].value = 0.0
                        if magnetic[f] and compassPaused:
                            compassPaused = False
                            with open(statepath[f], "w") as s:
                                s.write("0")
                                s.close()
                        #print str(f) + "OFF\n"
        t -= 0.001
        time.sleep(0.001)
    i += 1
    for f in range (0, len(filepath)):
        if i >= instrSize[f]:
            i = 0

########################################################:
#        print "working with " + str(i)
#    if (state == 0):
#        state = 1
#        sol.on()
#        sleep(0.2)
#    else:
#        state = 0
#        sol.off()
#        sleep(2)
    
