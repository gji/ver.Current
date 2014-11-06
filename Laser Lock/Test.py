from ScanLib import Scan
from pyqtgraph.Qt import QtGui, QtCore
import pyqtgraph as pg
import pyqtgraph.widgets.RemoteGraphicsView
import numpy as np
from random import random
import time
import math
from scipy import stats
import scipy as sc
import peak_detect as pd
from PID import PID
import bottleneck

app = pg.mkQApp()
pg.setConfigOptions(background="#FFF")

view = pg.widgets.RemoteGraphicsView.RemoteGraphicsView(background=None)
view.pg.setConfigOptions(antialias=True, foreground="#888")  ## prettier plots at no cost to the main process!
view.setWindowTitle('Cavity Lock')

label = QtGui.QLabel()
start = QtGui.QPushButton("Start Lock")
lockPoint = QtGui.QLineEdit()

layout = QtGui.QGridLayout()
layout.addWidget(label,0,0,2,1)
layout.addWidget(start,1,0)
layout.addWidget(lockPoint,1,1)
layout.addWidget(view,0,2,2,1)
layout.setColumnStretch(0,0)
layout.setColumnStretch(1,0)
layout.setColumnStretch(2,1)
w = QtGui.QWidget()
w.setLayout(layout)
w.show()

cavityScan = Scan()
cavityScan.setTriangleSweep(0.4, 1.0, 1000)


## Create a PlotItem in the remote process that will be displayed locally
rplt = view.pg.PlotItem()
rplt._setProxyOptions(deferGetattr=True)  ## speeds up access to rplt.plot
view.setCentralItem(rplt)

lastUpdate = pg.ptime.time()
avgFps = 0.0

LaserLock_369 = PID(P=0.0, I=0.1, D=0)
setpoint=0.1
cavityScan.setVoltage(0, 0)

def isZeroX(arr):
    a = arr[0]
    b = arr[1]
    c = arr[2]
    d = arr[3]
    e = arr[4]
    s = (-0.632456*a - 0.316228*b + 0.316228*d + 0.632456*e)
    if s > -0.00005: return False
    x = -1.41421* (0.447214*a + 0.447214*b + 0.447214*c + 0.447214*d + 0.447214*e)/s
    if x <= 1 and x >= -1:
        return True
    else:
        return False

def rolling_window(a, window):
    shape = a.shape[:-1] + (a.shape[-1] - window + 1, window)
    strides = a.strides + (a.strides[-1],)
    return np.lib.stride_tricks.as_strided(a, shape=shape, strides=strides)

def update():
    global setpoint, LaserLock_369, cavityScan, check, label, plt, lastUpdate, avgFps, rpltfunc
    a0, a1 = cavityScan.getScan()

    R=5
    pad_size = math.ceil(float(a0.size)/R)*R - a0.size
    a0_p = np.append(a0, np.zeros(pad_size)*np.NaN)
    a1_p = np.append(a1, np.zeros(pad_size)*np.NaN)
    a0_p = stats.nanmean(a0_p.reshape(-1,R), axis=1)
    a1_p = stats.nanmean(a1_p.reshape(-1,R), axis=1)

    #print "trying to find peaks"
    #for i in signal.find_peaks_cwt(a0_p, np.arange(1,100)):
    #    rplt.addLine(x=i)
    #print "done!"
    #print peakind
    #rplt.plot(a0_p, clear=True, _callSync='off', pen=0)
    #rplt.plot(a1_p, _callSync='off', pen="#00F")

    # da0 = np.diff(a0)[1:-1]
    # da1 = np.diff(a1)[1:-1]
    # da0 = sc.convolve(da0, np.ones(200)/200)
    # da1 = sc.convolve(da1, np.ones(200)/200)
    # da0 = sc.convolve(da0, [-0.2,-0.1,0,0.1,0.2])
    # pad_size = math.ceil(float(da0.size)/R)*R - da0.size
    # da0_p = np.append(da0, np.zeros(pad_size)*np.NaN)
    # da0_p = stats.nanmean(da0_p.reshape(-1,R), axis=1)
    # da1_p = np.append(da1, np.zeros(pad_size)*np.NaN)
    # da1_p = stats.nanmean(da1_p.reshape(-1,R), axis=1)
    # rw = rolling_window(da0_p,5)
    # i=0


    # for x in rw:
    #     i = i+1
    #     isZeroX(x)
        #    rplt.addLine(x=i*R)


    #mda0_p = np.nanargmin(da0_p)
    #rplt.plot(mda0_p, clear=True, _callSync='off', pen=0)
    _max, _min = pd.peakdetect(a0_p, lookahead=100, delta=0.1)
    found = []
    for x in _max:
        if x[1] > 0.24:
            found.append(x)
            if len(found)==2: break

    rplt.plot(a0_p, clear=True, _callSync='off', pen=0)

    if len(found)==2:
        found = pd._peakdetect_parabole_fitter(found, np.arange(0,len(a0_p)), a0_p, 7)
        pos_780 = found[0][0]
        pos_780_2 = found[1][0]

        _max, _min = pd.peakdetect(a1_p[int(pos_780):-1], lookahead=70, delta=0.05)
        found_369 = False
        for x in _max:
            if x[1] > 0.20:
                found_369 = [x[0]+int(pos_780),x[1]]
                break
        found_369 = pd._peakdetect_parabole_fitter([found_369], np.arange(0,len(a1_p)), a1_p, 7)[0]
        pos_369 = found_369[0]

        r = (pos_369-pos_780)/(pos_780_2-pos_780)
        if setpoint==0.1:
            setpoint = r
            LaserLock_369.setPoint(setpoint)
        else:
            err = LaserLock_369.update(r)
            cavityScan.setVoltage(err, 0)

    #if not found_369: print "couldn't find a 369 peak!"

        rplt.addLine(x=pos_369, _callSync='off')
        rplt.addLine(x=pos_780, _callSync='off')
        rplt.addLine(x=pos_780_2, _callSync='off')
    rplt.plot(a1_p, _callSync='off', pen="#00F")

    #time.sleep(0.05)
    #time.sleep(5)


    now = pg.ptime.time()
    fps = 1.0 / (now - lastUpdate)
    lastUpdate = now
    avgFps = avgFps * 0.95 + fps * 0.05
    label.setText("Operating at %(a)0.2f scans/sec\nOffset from LP is %(b)0.4f" % {'a':avgFps, 'b':(setpoint-r)})
        
timer = QtCore.QTimer()
timer.timeout.connect(update)
timer.start(0)


## Start Qt event loop unless running in interactive mode or using pyside.
if __name__ == '__main__':
    import sys
    if (sys.flags.interactive != 1) or not hasattr(QtCore, 'PYQT_VERSION'):
        QtGui.QApplication.instance().exec_()