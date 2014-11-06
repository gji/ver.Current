import ok
import sys
import string
import time
import struct
import binascii
import numpy as np
#import matplotlib
#matplotlib.use('WXAgg')
from matplotlib import pyplot as plt

class Scan:
	def __init__(self):
		self.xem = ok.okCFrontPanel()
		if (self.xem.NoError != self.xem.OpenBySerial("")):
			print ("A device could not be opened.  Is one connected?")
			#return(False)

		devInfo = ok.okTDeviceInfo()
		if (self.xem.NoError != self.xem.GetDeviceInfo(devInfo)):
			print ("Unable to retrieve device information.")
			exit
		print("Got device: " + devInfo.productName)

		if (self.xem.NoError != self.xem.ConfigureFPGA("cavity.bit")):
			print ("FPGA configuration failed.")
			exit

	def setSawtoothSweep(self, offset, rampAmp, freq):
		self.xem.ActivateTriggerIn(0x41, 0) # resets DAC memory address
		volt = bytearray()
		for voltage in [offset + (rampAmp * x / (1000000.0/freq)) for x in range(int(1000000/freq))]:
			channel = 3
			if(voltage < 0): voltage = 0 # no negative voltage!
			if(voltage > 4.095): voltage = 4.095
			volt += struct.pack('<h', int(32768 * voltage / 4.096) ) + struct.pack('<b', channel)  + "\x00"
		self.xem.WriteToPipeIn(0x9C, volt)

	def setTriangleSweep(self, offset, rampAmp, freq):
		self.xem.ActivateTriggerIn(0x41, 0) # resets DAC memory address
		volt = bytearray()
		freq = freq/2
		voltramp =  [offset + (rampAmp * x / (1000000.0/freq)) for x in range(int(1000000/freq))]
		for voltage in voltramp+(voltramp[::-1]):
			channel = 3
			if(voltage < 0): voltage = 0 # no negative voltage!
			if(voltage > 4.095): voltage = 4.095
			volt += struct.pack('<h', int(32768 * voltage / 4.096) ) + struct.pack('<b', channel)  + "\x00"
		self.xem.WriteToPipeIn(0x9C, volt)

	def setupSweep(self):
		self.xem.ActivateTriggerIn(0x40, 0)
		time.sleep(0.1)
		self.xem.UpdateWireOuts()
		self.xem.ReadFromPipeOut(0xA0, bytearray("\x00"*4*self.xem.GetWireOutValue(0x22)) )

	def setVoltage(self, voltage, channel):
		if(voltage < -4.096): voltage = -4.096
		if(voltage > 4.095): voltage = 4.095
		volt = struct.unpack('>i', "\x00" + struct.pack('>b', channel)  + struct.pack('>h', int(32768 * voltage / 4.096) ))[0]
		self.xem.SetWireInValue(0x00,volt)
		self.xem.UpdateWireIns()
		self.xem.ActivateTriggerIn(0x40, 1) # trigger for special stuff

	def getScan(self):
		self.xem.ActivateTriggerIn(0x40, 0) # start acquisition
		ts = []
		volt = []
		ad0 = []
		ad1 = []
		while True:
			self.xem.UpdateWireOuts()
			samples = self.xem.GetWireOutValue(0x22)
			volt.append(self.xem.GetWireOutValue(0x21))
			ts.append(samples)
			if samples == 0:
				break
			buf = bytearray("\x00"*4*samples)
			self.xem.ReadFromPipeOut(0xA0, buf)
			a = np.array(buf).view(np.int16).reshape((-1,2))
			ad0 = np.append(ad0,a[:,0])
			ad1 = np.append(ad1,a[:,1])
		#print len(ad0)
		ad0 = 2.048*(ad0-8192)/8192
		ad1 = 2.048*(ad1-8192)/8192
		#plt.plot(ad0)
		#plt.show()
		return ad0, ad1


if __name__ == '__main__':
    cavityScan = Scan()
    cavityScan.setVoltage(0.0,0)