import subprocess
import csv
import time, datetime
import MySQLdb as mdb
from PID import PID
from ADDA import ADDA
from setVoltage import SetVoltage
import winsound
import atexit

import requests
import re
import os

def getChannels():    
    const= [0 for i in range(16)]
    with open('setpoints.csv','r+') as csvfile:
        reader = csv.reader(csvfile, delimiter=' ')
        i=0
        for row in reader:
            const[i] = row[2]
            const[i] = float(const[i])
            i+=1
        i-=1
        Channels = int(const[i])
    return Channels

def getSetpoints():
    cur.execute("SELECT * FROM `wavemeter`.`setpoint`")
    rows = cur.fetchall()
    if(len(rows) > 0): return rows[0]
    else: return None
    # Channels = getChannels()
    # setPoints= [0 for i in range(Channels)]
    # with open('setpoints.csv','r+') as csvfile:
    #     reader = csv.reader(csvfile, delimiterk
    #     for row in reader:
    #         setPoints[i] = row[2]
    #         setPoints[i] = float(setPoints[i])
    #         i+=1
    #         if i== Channels:
    #             break
    # return setPoints

def getFreqs():
    Channels = getChannels()
    name = "WavemeterData.exe "
    name = name+str(3)
    with open(os.devnull, "w") as fnull:
        test = subprocess.call(name, stdout = fnull)
    waveOut = str(subprocess.check_output(name))
    waveOut = waveOut.split(" ")
    test = waveOut   
    freq = [0,0,0]
    freq[0] = float(waveOut[0])
    freq[1] = float(waveOut[2])
    freq[2] = float(waveOut[1])
    # j=0

    # headers = {'content-type': 'application/json'}
    # url = "http://192.168.2.50/wavemeter/wavemeter/wavemeter-status"
    # dataSend = "5|0|5|http://192.168.2.50/wavemeter/wavemeter/|CAE770F80E4A681B200769F57E4D8989|edu.umd.ion.wavemeter.service.WavemeterService|pollWavemeter|edu.umd.ion.wavemeter.service.WavemeterDataMask/1786418976|1|2|3|4|1|5|5|0|1918500334|"
    # headers = {'Content-Type':'text/x-gwt-rpc; charset=utf-8','X-GWT-Permutation':'E1D57440910859B69F5FD923FD39B973','X-GWT-Module-Base':'http://192.168.2.50/wavemeter/wavemeter/'}
    # r = requests.post(url, data=dataSend, headers = headers)

    # result = re.match(r"\/\/OK\[(.+)\]", r.text)
    # wavelengths = result.groups()[0].split(',')
    # # print wavelengths
    # # print wavelengths[118]
    # # print 299792.458 / float(wavelengths[55])
    # freq[1] = 299792.458 / float(wavelengths[55])
    #freq[2] = float(wavelengths[244])
    #print freq[2]
    return freq
def getErrors():
    Channels = getChannels()
    freqError = [0 for i in range(Channels)]
    setPoints = getSetpoints()
    freqAct = getFreqs()    
    j=0
    while True:
        freqError[j] = freqAct[j]-setPoints[j]
        j+=1
        if j == Channels:
            break
    return freqError


def Lock(con, cur):
    setPoints = getSetpoints()

    LaserLock_369 = PID(P=-50, I=-500, D=0)
    LaserLock_399 = PID(P=20, I=20, D=0)
    LaserLock_935 = PID(P=40, I=60, D=0)

    LaserLock_369.setPoint(setPoints[0])
    LaserLock_399.setPoint(setPoints[1])
    LaserLock_935.setPoint(setPoints[2]) 

    ADDA1.setVoltage(0,0)
    ADDA1.setVoltage(1,0)
    ADDA1.setVoltage(2,0)

    timeFlag_1 = False
    overTime = time.mktime(datetime.datetime.now().timetuple())

    errorCount=0
    while True:
        freq = getFreqs()
        t = getSetpoints()
        if(t != None):
            setPoints = getSetpoints()
            if(LaserLock_369.set_point != setPoints[0]): LaserLock_369.setPoint(setPoints[0])
            if(LaserLock_399.set_point != setPoints[1]): LaserLock_399.setPoint(setPoints[1])
            if(LaserLock_935.set_point != setPoints[2]): LaserLock_935.setPoint(setPoints[2])

        for i in range(len(freq)):
            if freq[i]<0:
                freq[i] = setPoints[i]
            if abs(freq[i]-setPoints[i]) > 0.01: # > 10 Ghz or 0.01nm? probably a mode hop
            	freq[i] = setPoints[i] # wait to try and recover
            
        #freq[0] = setPoints[0]
        error_369 = LaserLock_369.update(freq[0])
        error_399 = LaserLock_399.update(freq[1])
        error_935 = LaserLock_935.update(freq[2])

        #print freq
        #print setPoints
        print round(error_369,4), round(error_399,4), round(error_935,4)
        if (error_369>=5) or(error_399>=5) or(error_935>=5) or(error_369<=-5) or(error_399<=-5) or(error_935<=-5):
            errorCount += 1
        else:
            errorCount = 0
        if errorCount > 3:
       #     winsound.PlaySound("SystemQuestion", winsound.SND_ALIAS)
        #    winsound.PlaySound("SystemQuestion", winsound.SND_ALIAS)
         #   winsound.PlaySound("SystemQuestion", winsound.SND_ALIAS)
          #  winsound.PlaySound("SystemQuestion", winsound.SND_ALIAS)
            ADDA1.setVoltage(0,0)
            ADDA1.setVoltage(1,0)
            ADDA1.setVoltage(2,0)
            print "Lock Broken!"
            break
  
        ADDA1.setVoltage(0, error_369)
        ADDA1.setVoltage(1, error_399)
        ADDA1.setVoltage(2, error_935)
        cTime = time.mktime(datetime.datetime.now().timetuple())*1e3 + datetime.datetime.now().microsecond/1e3

        #cur.execute("INSERT INTO `wavemeter`.`error`( `index`, `time`, `739`, `935`, `739w`, `935w`) VALUES (NULL, \'%s\',\'%s\',\'%s\',\'%s\',\'%s\');",(cTime,error_2,error_1, freq[1], freq[0]))
        #con.commit()

        cur.execute("INSERT INTO `wavemeter`.`error` (time, `369`, `399`, `935`, 369w, 399w, 935w) VALUES (\'%s\',\'%s\',\'%s\',\'%s\',\'%s\',\'%s\',\'%s\');",(cTime,round(error_369,4), round(error_399,4), round(error_935,4), freq[0], freq[1], freq[2]))
        con.commit() 

        time.sleep(.2)
        # break


@atexit.register
def reset_voltages():
    print "killed!"
    ADDA1.setVoltage(0,0)
    ADDA1.setVoltage(1,0)
    ADDA1.setVoltage(2,0)


ADDA1 = ADDA()
con = mdb.connect('192.168.9.2', 'python', 'dTh6xh', 'wavemeter')
cur = con.cursor()
cur.execute("TRUNCATE TABLE `error`")
Lock(con, cur)

#some change
#another change