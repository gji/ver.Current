import serial 
from datetime import datetime
import re
import numpy
import threading
import matplotlib.pyplot as plt

n=2048
xRan = range(0,n)

flag = False

plt.ion()

ser = serial.Serial(port=6,baudrate=230400,timeout=None,stopbits=serial.STOPBITS_TWO)
ser.flushInput()

data=[];

while True:
	s = ser.read(6)


	out = (ord(s[5]) & 0b00011111)*(256 ** 5) + (ord(s[4]))*(256 ** 4) + (ord(s[3]))*(256 ** 3) + (ord(s[2]))*(256 ** 2) + (ord(s[2]))*(256 ** 1) + (ord(s[0]))*(256 ** 0)
	out /=1000000.0
	data.append(out)

	print out
	plt.clf()
	plt.hist(data, bins=10)
	plt.draw()
	#print map(ord,s)

ser.close()