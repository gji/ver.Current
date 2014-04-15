import ok
import sys
import string
import time
import struct

class ADDA:
	def __init__(self):
		voltages = [0,0,0,0]

		self.xem = ok.okCFrontPanel()
		if (self.xem.NoError != self.xem.OpenBySerial("")):
			print ("A device could not be opened.  Is one connected?")
			#return(False)

		devInfo = ok.okTDeviceInfo()
		if (self.xem.NoError != self.xem.GetDeviceInfo(devInfo)):
			print ("Unable to retrieve device information.")
			exit
		print("Got device: " + devInfo.productName)

		if (self.xem.NoError != self.xem.ConfigureFPGA("dac.bit")):
			print ("FPGA configuration failed.")
			exit

	def setVoltage(self, channel, voltage):
		if(voltage < -4.096): voltage = -4.096
		if(voltage > 4.095): voltage = 4.095
		volt = struct.unpack('>i', "\x00" + struct.pack('>b', channel)  + struct.pack('>h', int(32768 * voltage / 4.096) ))[0]
		self.xem.SetWireInValue(0x00,volt)
		self.xem.UpdateWireIns();
		self.xem.ActivateTriggerIn(0x40, 0)


ADDA1 = ADDA()
ADDA1.setVoltage(0,0)
ADDA1.setVoltage(1,0)
ADDA1.setVoltage(2,0)