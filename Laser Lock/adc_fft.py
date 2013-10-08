import serial 
from datetime import datetime
import re
import pylab
import scipy
from scipy import signal
import scipy.fftpack
import numpy
import threading

def ByteToHex( byteStr ):
    return ''.join( [ "%02X" % ord( x ) for x in byteStr ] ).strip()


n=2048
xRan = range(0,n)

flag = False

pylab.ion()

ser = serial.Serial(port=3,baudrate=921600,timeout=3,stopbits=serial.STOPBITS_TWO)
ser.flushInput()
ser.write(bytearray.fromhex("64 00 FF 6c 00 00"))

while True:

	#print "START" + datetime.now().__str__()
	chA = []
	chB = []
	ser.write("r")
	s = ByteToHex(ser.read(n*2*2)) # 16 byte stuff, two channels

	#print "GOT DATA" + datetime.now().__str__()

	s = re.sub(r'(..)(..)', r'\2\1',s)
	s = map(''.join, zip(*[iter(s)]*4))
	xRan = range(0,n)
	#chB = map(lambda x: int(x,16), s)

	#nbins = max(chB) - min(chB) + 1
	#hist, bins = numpy.histogram(chB,bins = min([nbins,100]), range = (min(chB),max(chB)))
	#width = 0.7*(bins[1]-bins[0])
	#center = (bins[:-1]+bins[1:])/2

	for i in range(0,len(s)):
		if(i%4==0): chA.append(int(s[i],16))
		elif (i%4==1): chB.append(int(s[i],16))

	#norm = float(sum(chB))/len(chB)
	#chB = map(lambda x: 4*(x-8178.0)/16384.0,chB)

	#print numpy.average(chB)
	#print numpy.std(chB)
	#chB_windowed = signal.flattop(len(chB)) * chB
	#fftB = abs(scipy.fft(chB_windowed))
	#fftB = numpy.divide(fftB,4096)
	#freqs = scipy.fftpack.fftfreq(len(chB), t[1]-t[0])

	#print "PROCESSED" + datetime.now().__str__()

	#pylab.clf()
	if not flag:
		t = scipy.linspace(0,len(chA)*(19/80000000.0),len(chA))
		line1, line2, line3, line4 = pylab.plot(t, chA, t, chB, t, numpy.gradient(chA), t, numpy.gradient(chB))
		flag = True
	else:
		line1.set_ydata(chA)
		line2.set_ydata(chB)
		line3.set_ydata(numpy.gradient(chA))
		line4.set_ydata(numpy.gradient(chB))
	#pylab.subplot(312)
	#pylab.plot(freqs[0:freqs.size/2],20*scipy.log10(fftB[0:freqs.size/2]),'r-')
	#pylab.ylim([-125,0])
	#pylab.subplot(313)
	#pylab.bar(center, hist, align = 'center', width = width)
	pylab.draw()
	#pylab.show()

ser.close()