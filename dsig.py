from gpiozero import PWMOutputDevice
from gpiozero import DigitalOutputDevice
import os
import time
import re
import random
from collections import deque

#########################################################################
# instruction | behaviour                                               #
#-------------|---------------------------------------------------------#

#digOut = [DigitalOutputDevice(5), DigitalOutputDevice(6)]
out = [PWMOutputDevice(12), PWMOutputDevice(13), DigitalOutputDevice(6), DigitalOutputDevice(23)]
outType = ["pwm","pwm","dig", "dig"]
state = [0.0,0.0,0.0,0.0]
basebeat = 64.0
baseSpeedDiv = 270.0
speedDivider = baseSpeedDiv 
beatlength = basebeat/speedDivider
magnetic = [True,True,True,False]
#look in the following files for instructions
speedDivPath = "/home/pi/nsdata/gpio/sig_speeddiv.o"
filepath = ["/home/pi/nsdata/gpio/dsig_r.o", "/home/pi/nsdata/gpio/dsig_l.o", "/home/pi/nsdata/gpio/dsig_b.o", "/home/pi/nsdata/gpio/dsig_i.o"]
statepath = ["/home/pi/nsdata/gpio/mag1.s", "/home/pi/nsdata/gpio/mag2.s", "/home/pi/nsdata/gpio/mag3.s", "/home/pi/nsdata/gpio/mag_null.s"]
#make two double ended queues for instructions, one for eeach of the digital outs
#queuedInstruction = [deque(['s']), deque(['s']), deque(['s'])]
activeInstruction = [ {'inspecting':0, 'timepassed':0.0, 'instr': "", 'instrset': [{'force':0.0, 'dur':64.0}]},
                      {'inspecting':0, 'timepassed':0.0, 'instr': "", 'instrset': [{'force':0.0, 'dur':64.0}]},
                      {'inspecting':0, 'timepassed':0.0, 'instr': "", 'instrset': [{'force':0.0, 'dur':64.0}]},
                      {'inspecting':0, 'timepassed':0.0, 'instr': "", 'instrset': [{'force':0.0, 'dur':64.0}]} ]

defaultInstruction = {'force':0.0, 'dur':basebeat}
instrLibrary = {};

for sp in statepath:
    with open(sp, "w") as s:
        s.write("0")
        s.close()
#for instr in activeInstruction:
#    instr.clear()

def combineInstrSets(instrParts, maxdur):
    comboInstr = {'ttldur':maxdur, 'set':[]}
    ele = {'force':0.0, 'dur':0.0}
    for d in range(0,int(maxdur)):
      print "examining dur unit " + str(d)
      force = 0.0
      for ip in instrParts:
        p = ip['place']
        if p < ip['length']:
          ins = ip['set'][p]
          print "adding " + str(ins['force']) + " to force\n"
          force += ins['force']
          if ins['dur'] + ip['durlapsed'] < d:
            ip['durlapsed'] += ins['dur']
            ip['place'] += 1
      if force == ele['force']:
        ele['dur'] +=1
        print "continuing.. add 1 to dur"
      else:
        comboInstr['set'].append(ele)
        ele = {'force':force, 'dur':1.0}
    return comboInstr

def adjDurAndForce(instr):
    check = instr['ttldur'] > basebeat
    if check:
      adj = basebeat/instr['ttldur']
    else:
      adj = 1
    for ind in instr['set']:
      if ind['force'] > 1.0:
        ind['force'] = 1.0
      ind['dur'] = (ind['dur'] * adj)/speedDivider;
    return instr

def processLineset(ls):
    lineset = ls.split("-")
    iset = []
    ttldur = 0.0
    for l in lineset:
      match = re.match(r'd(\d+)@f(\d+)', l, re.M|re.I)
      if match:
        dur = float(match.group(1))
        force = float(match.group(2))/100.0
        ele = {'force': force, 'dur': dur}
        ttldur += ele['dur']
        iset.append(ele)
    rtn = {'ttldur': ttldur, 'set': iset, 'length': len(iset), 'place':0, 'durlapsed':0}
    return rtn

def getInstrFromFile(fileName, i, prevInstr):
    with open(fileName) as f:
        lines = f.read().splitlines()
        newInstr ={'inspecting':0, 'timepassed':0.0, 'instr': "", 'instrset': []}
        if len(lines) > i:
#        print "lines read\n"
          if prevInstr['instr'] != lines[i]:
            try:
              newInstr['instrset'] = instrLibrary[lines[i]]
              newInstr['instr'] = adjDurAndForce(lines[i])
            except:
              newInstr['instr'] = lines[i]
              instrSets = []
              linesets = lines[i].split("|")
              maxdur = 0.0
              for ls in linesets:
                iset = processLineset(ls)
                if iset['ttldur'] > maxdur:
                  maxdur = iset['ttldur']
                instrSets.append(iset)
              setLen = len(instrSets)
              if setLen > 1:
                combinedInstr = combineInstrSets(instrSets, maxdur)   
                instrLibrary[lines[i]] = list(combinedInstr['set'])
                resolvedInstr = adjDurAndForce(combinedInstr)
                newInstr['instrset'] = list(resolvedInstr['set'])    
              elif setLen == 1:
                instrLibrary[lines[i]] = list(instrSets[0]['set'])
                resolvedInstr = adjDurAndForce(instrSets[0])
                newInstr['instrset'] = list(resolvedInstr['set'])    
          else:
            newInstr['instr'] = str(prevInstr['instr'])
            newInstr['instrset'] = list(prevInstr['instrset'])
        if len(newInstr) == 0:
          newInstr['instrset'].append(defaultInstruction)  
        return newInstr

def getSpeedDivFromFile(fileName):
    with open(fileName) as f:
        line = f.read()
        try:
            rtn = float(line)
        except:
            return baseSpeedDiv
        else:
            if (rtn > baseSpeedDiv): 
                return rtn
            else:
                return baseSpeedDiv

def pauseCompass(onoff):
    with open(statepath[f], "w") as s:
        s.write(onoff)
        s.close()
    if onoff == "1":
        return True
    else:
        return False 

def setSignalToNewValue(sig):
    if sig > 0.0:
        if magnetic[f]:
            pauseCompass("1")
        elif magnetic[f]:
            pauseCompass("0")
    if outType[f] == "pwm":
        out[f].value = sig
    elif outType[f] == "dig":
        if sig > 0:
            out[f].on() 
        else: out[f].off()

def logOutput(actIn, i, fn):
    with open('/home/pi/nsdata/gpio/dsig-log/' + fn + '.o', 'a') as logfile:
      po = "scorePlace,dur,force\n"
      for e in actIn['instrset']:
        po += str(i)"," + str(e['dur']) + "," + str(e['force']) + "\n" 
      logfile.write(po)


i = 0
instrSize = [10,10,10,10]
while True:
    speedDivider = getSpeedDivFromFile(speedDivPath) # Get the present 'SpeedDiv' file - higher numbers = faster.
    beatlength = basebeat/speedDivider               # The beatlength here is the base 'beat' value divider by the speed div - this is how 
                                                     # | many seconds the beat will last
    for f in range(0, len(filepath)):                # It's time to check to see if there are any new rhythm instructions in each designated filepath
        activeInstruction[f] = getInstrFromFile(filepath[f], i, activeInstruction[f])
    t = beatlength                                       # The value t is set to the whole duration of a standard beat
    lasttime = time.time()
    while (t > 0.0):
        for f in range(0, len(filepath)):
            p = activeInstruction[f]['inspecting']
            if i < instrSize[f] and p < len(activeInstruction[f]['instrset']) :
              instr = activeInstruction[f]['instrset'][p]
             # print activeInstruction[f]['instrset']
             # print instr
              if state[f] != instr['force']:
                  state[f] = instr['force']
                  setSignalToNewValue(instr['force'])
              if (beatlength - instr['dur'] - activeInstruction[f]['timepassed']) > t:
                  activeInstruction[f]['inspecting'] += 1
        nowtime = time.time() 
        gap = nowtime - lasttime
        t -= gap
        lasttime = nowtime
        #print "now: " +str(nowtime) + " before: " + str(lasttime) + " t: " + str(t)
        time.sleep(0.005)
    logOutput(activeInstruction[0], i, "r")
    logOutput(activeInstruction[1], i, "l")
    i += 1
    for f in range (0, len(filepath)):
        if i >= instrSize[f]:
            i = 0
