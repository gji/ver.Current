from ScanLib import Scan
import numpy as np
import time
from matplotlib import pyplot as plt

plt.ion()

cavityScan = Scan()

cavityScan.setTriangleSweep(0, 1.5, 1000)
#cavityScan.setupSweep()

while True:
	#raw_input("Press Enter to continue...")
	a0, a1 = cavityScan.getScan()
	plt.clf()
	plt.plot(a0)
	plt.pause(0.000001)
