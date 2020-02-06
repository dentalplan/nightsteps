from gpiozero import PWMOutputDevice
from gpiozero import DigitalOutputDevice
import os
import time
import re
from collections import deque

#########################################################################
# instruction | behaviour                                               #
#-------------|---------------------------------------------------------#

#digOut = [DigitalOutputDevice(5), DigitalOutputDevice(6)]
out = [PWMOutputDevice(12), PWMOutputDevice(13), DigitalOutputDevice(23)]
outType = ["pwm","pwm","dig"]
state = [0,0,0]
basebeat = float(70)
baseSpeedDiv = float(70)
speedDivider = baseSpeedDiv 
beatlength = basebeat/speedDivider
magnetic = [True,True,False]
compassPaused = False
#look in the following files for instructions
speedDivPath = "/home/pi/nsdata/gpio/sig_speeddiv.o"
filepath = ["/home/pi/nsdata/gpio/sig_r.o", "/home/pi/nsdata/gpio/sig_l.o", "/home/pi/nsdata/gpio/sig_i.o"] #, "/home/pi/nsdata/gpio/sig_i.o"]
statepath = ["/home/pi/nsdata/gpio/mag1.s", "/home/pi/nsdata/gpio/mag2.s"] #, "/home/pi/nsdata/gpio/mag3.s"]
#make two double ended queues for instructions, one for eeach of the digital outs
#queuedInstruction = [deque(['s']), deque(['s']), deque(['s'])]
activeInstruction = [{'force':0, 'dur':0}, {'force':0, 'dur':0}, {'force':0, 'dur':0}]#, deque(['s'])]
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
instrSize = [20,20,20]
while True:
    speedDivider = getSpeedDivFromFile(speedDivPath) # Get the present 'SpeedDiv' file - higher numbers = faster.
    beatlength = basebeat/speedDivider               # The beatlength here is the base 'beat' value divider by the speed div - this is how 
                                                     # | many seconds the beat will last
    for f in range(0, len(filepath)):                # It's time to check to see if there are any new rhythm instructions in each designated filepath
        activeInstruction[f] = getInstrFromFile(filepath[f], i)
        if activeInstruction[f]['dur'] >= 0.0:
            if activeInstruction[f]['dur'] > ((basebeat/5.0) * 3.0):  # Strikes on the solenoid are restricted to 3/5s of the beat. If they
                activeInstruction[f]['dur'] = (basebeat/5.0) * 3.0    # | go over this then it changed to 3/5.
            if activeInstruction[f]['force'] > 100:               # Likewise, strikes should not have more than 100% force
                activeInstruction[f]['force'] = 100       
    t = beatlength                                       # The value t is set to the whole duration of a standard beat
    lasttime = time.time() 
    while (t > 0.0):
        for f in range(0, len(filepath)):
            if i < instrSize[f]:
                strikelength = activeInstruction[f]['dur']/speedDivider
                if t > (beatlength - strikelength) and (state[f] == 0):
                        state[f] = 1.0
                        if magnetic[f] and compassPaused == False:
                            compassPaused = True
                            with open(statepath[f], "w") as s:
                                s.write("1")
                                s.close()
                        if outType[f] == "pwm":
                            out[f].value = activeInstruction[f]['force']/100
                        elif outType[f] == "dig":
                            if activeInstruction[f]['force'] > 0:
                                out[f].on() 
                            else: out[f].off()
                elif t <= (beatlength - strikelength) and (state[f] == 1):
                        state[f] = 0
                        if outType[f] == "pwm":
                            out[f].value = 0.0
                        elif outType[f] == "dig":
                            out[f].off()
                        if magnetic[f] and compassPaused:
                            compassPaused = False
                            with open(statepath[f], "w") as s:
                                s.write("0")
                                s.close()
                        #print str(f) + "OFF\n"
        nowtime = time.time() 
        gap = nowtime - lasttime
        t -= gap
        lasttime = nowtime
        #print "now: " +str(nowtime) + " before: " + str(lasttime) + " t: " + str(t)
        time.sleep(0.005)
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
    
