from gpiozero import PWMOutputDevice
import os
import time
import re
from collections import deque

#########################################################################
# instruction | behaviour                                               #
#-------------|---------------------------------------------------------#

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
activeInstruction = [{'force':0, 'dur':0}, {'force':0, 'dur':0}]#, deque(['s'])]
for sp in statepath:
    with open(sp, "w") as s:
        s.write("0")
        s.close()
#for instr in activeInstruction:
#    instr.clear()

def getInstrFromFile(fileName, i):
    with open(fileName) as f:
        lines = deque (f.read().splitlines())
        if len(lines) > 0:
#        print "lines read\n"
            match = re.match(r'o(\d+)-(\d+)', lines[i], re.M|re.I)
            if match:
                force = float(match.group(1))
                dur  = float(match.group(2))
                instr = {'force': force, 'dur': dur} 
            else:
                instr = {'force': 0.0, 'dur': -1.0} 
        else:
            instr = {'force': 0.0, 'dur': -1.0} 
        return instr

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
        activeInstruction[f] = getInstrFromFile(filepath[f], i)
        #instrSize[f] = len(activeInstruction[f])
#        print "Instr Size " + str(f) + " is " +  str(instrSize[f])
        if activeInstruction[f]['dur'] >= 0.0:
#            print "File " + str(f) + " of " + str(len(filepath)) + "; instr " + str(i) + " of " + str(instrSize[f])
            if activeInstruction[f]['dur'] > ((beat/5.0) * 3.0):
                activeInstruction[f]['dur'] = (beat/5.0) * 3.0
            if activeInstruction[f]['force'] > 100:
                activeInstruction[f]['force'] = 100
    t = tempo
    #print tempo
    while (t > 0.0):
#            print t
        for f in range(0, len(filepath)):
            if i < instrSize[f]:
                o = activeInstruction[f]['dur']/speedDivider
                #print o
                if t > (tempo - o) and (state[f] == 0):
                        state[f] = 1.0
                        if magnetic[f] and compassPaused == False:
                            compassPaused = True
                            with open(statepath[f], "w") as s:
                                s.write("1")
                                s.close()
                        pwm[f].value = activeInstruction[f]['force']/100
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
#    if (state == 0):/acti
#        state = 1
#        sol.on()
#        sleep(0.2)
#    else:
#        state = 0
#        sol.off()
#        sleep(2)
    
