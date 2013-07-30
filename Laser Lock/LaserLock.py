import subprocess
import csv
import time, datetime
import MySQLdb as mdb
from PID import PID
from setVoltage import SetVoltage
import winsound

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
    Channels = getChannels()
    setPoints= [0 for i in range(Channels)]
    with open('setpoints.csv','r+') as csvfile:
        reader = csv.reader(csvfile, delimiter=' ')
        i=0
        for row in reader:
            setPoints[i] = row[2]
            setPoints[i] = float(setPoints[i])
            i+=1
            if i== Channels:
                break
    return setPoints

def getFreqs():
    Channels = getChannels()
    name = "WavemeterData.exe "
    name = name+str(Channels)
    test = subprocess.call(name)
    waveOut = str(subprocess.check_output(name))
    waveOut = waveOut.split(" ")
    test = waveOut   
    freq = waveOut[:(Channels)]
    j=0
    while True:
        freq[j] = float(freq[j])
        j+=1
        if j == (Channels):
            break
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
   
   LaserLock_1 = PID(P=10, I=150, D=5) # 935nm
   LaserLock_2 = PID(P=-50, I=-300, D=3) # 739nm

   LaserLock_1.setPoint(setPoints[0])
   LaserLock_2.setPoint(setPoints[1]) 

   outputVolt_1 = SetVoltage(2.5, "Lock/ao1")
   outputVolt_2 = SetVoltage(2.5, "Lock/ao0")

   timeFlag_1 = False
   overTime = time.mktime(datetime.datetime.now().timetuple())

   #Funkytown:
   #winsound.Beep(1047,250) 
   #winsound.Beep(1047,250) 
   #winsound.Beep(932,250)
   #winsound.Beep(1047,500)
   #winsound.Beep(784,500)
   #winsound.Beep(784,250)
   #winsound.Beep(1047,250)
   #winsound.Beep(1397,250)
   #winsound.Beep(1319,250)
   #winsound.Beep(1047,250)


   errorCount=-1
   while True:
        freq = getFreqs()
        for i in range(len(freq)):
            if freq[i]<0:
                freq[i] = setPoints[i]
            elif(abs(freq[i] - setPoints[i])>.0001):
                #winsound.Beep(1397,200)
                winsound.Beep(440,200)
                errorCount+=1
                #whichSound = errorCount %4
                #if whichSound ==0:
                    #winsound.Beep(1568,333)
                    #winsound.Beep(1568,167)
                #elif whichSound ==1:
                    #winsound.Beep(1319,333)
                    #winsound.Beep(1760,167)
                #elif whichSound ==2:
                    #winsound.Beep(1568,500)
                #elif whichSound ==3:
                    #winsound.Beep(1319,500)
                    

               
        error_1 = min([max([(LaserLock_1.update(freq[0])+2.5),0]),5])
        error_2 = min([max([(LaserLock_2.update(freq[1])+2.5),0]),5])

        timeFlag_2 = (error_1 <0.01 or error_1 >4.99 or error_2 <0.01 or error_2 <0.01)
        if not(timeFlag_1 and timeFlag_2):
            overTime = time.mktime(datetime.datetime.now().timetuple())
            #print "reset"
        elif((time.mktime(datetime.datetime.now().timetuple()) - overTime)>= 5):
            outputVolt_1.setVolt(2.5)
            outputVolt_2.setVolt(2.5)
            winsound.Beep(1318,1000)
            winsound.Beep(1046,1000)
            winsound.Beep(880,1000)
            raise SystemExit("Railing Voltage")
                
        timeFlag_1 = timeFlag_2

        outputVolt_1.setVolt(error_1)
        outputVolt_2.setVolt(error_2)

        cTime = time.mktime(datetime.datetime.now().timetuple())*1e3 + datetime.datetime.now().microsecond/1e3

        cur.execute("INSERT INTO `wavemeter`.`error` (`index`, `time`, `739`, `935`, `739w`, `935w`) VALUES (NULL, \'%s\',\'%s\',\'%s\',\'%s\',\'%s\');",(cTime,error_2,error_1, freq[1], freq[0]))
        con.commit()

        print error_1, error_2
        time.sleep(.3)

#print time.mktime(datetime.datetime.now().timetuple())
con = mdb.connect('192.168.9.2', 'python', 'dTh6xh', 'wavemeter')
cur = con.cursor()
cur.execute("TRUNCATE TABLE `error`")
Lock(con, cur)