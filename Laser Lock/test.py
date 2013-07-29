
import subprocess

def getFreq(Channels):

    name = "WavemeterData.exe "
    name = name+str(Channels)

    subprocess.call(name)

    waveOut = str(subprocess.check_output(name))
    waveOut = waveOut.split("'")
    waveOut = waveOut[1].split(" ")
    freq = waveOut[:Channels]

    print(freq)
    return freq
   

def test():
    test = getFreq(2)
    print (test)

test()
