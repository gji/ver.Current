#pragma rtGlobals=1		// Use modern global access method and strict wave access.

//_____________________________________________________________________________
//
// PMTArrayOpen() opens the PMT FPGA serial communication port.
// When the port opens, the PMT should begin acquiring counts and 
// queuing them for transmission.
//_____________________________________________________________________________
//
function PMTArrayOpen()
	
	// Get the COM port number of the PMT FPGA
	SetDataFolder root:ExpParams
	SVAR PMT_PORT
	String pmt_p = PMT_PORT
	
	// Open the COM port and set the baud rate, etc
	VDT2/P=$pmt_p baud=115200,stopbits=1,killio
	VDTOpenPort2 $pmt_p
	VDTOperationsPort2 $pmt_p

end

//_____________________________________________________________________________
//
// PMTArrayClose() closes the PMT FPGA serial communication port.
//_____________________________________________________________________________
//
function PMTArrayClose()
	
	// Get the COM port number of the PMT FPGA
	SetDataFolder root:ExpParams
	SVAR PMT_PORT
	String pmt_p = PMT_PORT
	
	VDTClosePort2 $pmt_p

end

//_____________________________________________________________________________
//
// PMTArrayConfigure() sends a string to the PMT FPGA to configure the output binning
//_____________________________________________________________________________
//
function PMTArrayConfigure()
	
	// Construct the config byte string. The string starts with "Q". The subsequent 32 bytes encode the 
	// binning for the output channels. The first 4 bytes encode the binning for output channel 1.
	// The next 4 bytes encode the binning for output channel 2, and so on. In other words,
	// Send channels in 8 nybbles scanning the PMT channels backwards in sets of four channels:
	//	CH1(ch 29-32), CH1(ch 25-28), CH1(ch 21-24),  CH1(ch 17-20), CH1(ch 13-16), ... ,
	//	CH2(ch 29-32), CH2ch 25-28), CH2(ch 21-24),  CH2(ch 17-20), CH2(ch 13-16), ... ,
	//	...
	// Examples: 
	//	If PMT channel 1 and 4 are to be binned in output channel 1, the byte string looks like 
	//		"Q 00000090 00000000 00000000 00000000 00000000 00000000 00000000 00000000"
	//	If PMT channel 1, 4, and 31 are to be binned in output channel 2, the byte string looks like 
	//		"Q 00000000 40000090 00000000 00000000 00000000 00000000 00000000 00000000"
	//	This config string bins PMT channels 1, 2, 32 in output channel 1 and PMT channel 2 in output channel 2
	//	with all other output channels empty:
	//		Make/B/U/O PMTconfig = {0x51, 	0x80, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x02, 
	//										0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	//										0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	//										0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
	Make/B/U/O PMTconfig = {0x51, 0x00, 0x00, 0x00, 0x01, 	0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
	
	// Write to PMT FPGA with a timeout of 1 sec and low-byte-first ordering	
	VDTWriteBinaryWave2/B/O=1 PMTconfig
	//printf "Number of waves written: %d\r" V_VDT

	KillWaves PMTconfig

end

//_____________________________________________________________________________
//
// PMTArrayStatus() queries the PMT FPGA for the number of bytes available for download and
// if any errors are present. Returns the number of bytes available.
//_____________________________________________________________________________
//
function PMTArrayStatus()
	
	Variable bytesAvailable	// Number of bytes available in PMT FPGA outpu buffer
	SetDataFolder root:PMT
	VDTGetStatus2 0, 0, 0	// Get available bytes and store in global V_VDT
	bytesAvailable = V_VDT
	
	VDTGetStatus2 0, 1, 0	// Get error state and store in global V_VDT
	Variable j
	// Determine error code (based on VDT2 documentation)
	for (j=0;j<14;j+=1)
		if((V_VDT %& 2^j) != 0)
			//printf "Error: Bit %d\r" j
			break
		endif
	endfor
	
	return bytesAvailable
end

//_____________________________________________________________________________
//
// PMTArrayReadCounts(bytesAvailable) reads the available data in the PMT FPGA output buffer
// and stores it in a global wave
//_____________________________________________________________________________
//
function PMTArrayReadCounts(bytesAvailable)

	Variable bytesAvailable	// Number of bytes available in PMT FPGA outpu buffer
	
	SetDataFolder root:PMT
	Make/B/U/O/N=(bytesAvailable) PMTdata	// Create data storage wave of the proper length
	
	// Acquire PMT FPGA output data buffer
	VDTReadBinaryWave2/B/TYPE=0x8/O=1 PMTdata
	//printf "Waves actually read: %d\r" V_VDT
	//Print PMTdata
	
end

//_____________________________________________________________________________
//
// PMTArrayPoll(speed) repeatedly reads the PMT FPGA output data buffer into a storage wave
// with the speed of data acquisition provided as an input.
//_____________________________________________________________________________
//
Function PMTArrayPoll([speed])

	// The rate of acquisition is given by (60/speed) in units [reads/second]. This value cannot be
	// too slow or too fast or the PMT FPGA output buffer will either back up or not yet be 
	// populated with data
	Variable speed		// Optional input
	Variable bytesAvailable
	Variable totalBytesRead = 0
	Variable t0, j, m, n
	Variable k = 1
	Variable/G PMT_BUFFER
	Variable flag1, flag2
	
	// If speed is not input, set to optimal value
	if( ParamIsDefault(speed))
		speed = 30
	endif
		
	SetDataFolder root:PMT
	WAVE PMTdata		// Stores temporary PMT FPGA data buffer
	WAVE PMTcounts	// Stores complete 32-channel counts	
	MAKE/O/N=64 PMTArrayValues
	
	t0 = ticks	// Start the clock
	// Repeatedly acquire data until all 32 channel counts are collected
	do
		if (ticks - t0 > speed*k)	// Delay execution based on the desired speed
			bytesAvailable = PMTArrayStatus()
			if (bytesAvailable != 0)
				//printf "Bytes waiting to be read: %d\r" bytesAvailable
				PMTArrayReadCounts(bytesAvailable)
				// The data buffer is not always the same length, so it must be calculated each time
				for (j=0;j<numpnts(PMTdata);j+=1)
					if (totalBytesRead < PMT_BUFFER)
						PMTcounts[totalBytesRead]=PMTdata[j]
						totalBytesRead += 1
					else
						j = 0
						m = 0
						n = 0
						do
							if (PMTcounts[j] == 170 && flag1 == 0)
								flag2 = 0
								flag1 = 1
								j=mod(j+1,PMT_BUFFER)
								m=0
								continue
							endif
							if (PMTcounts[j] == 255 && flag1 == 1)
								flag2 = 1
								flag1 = 0
								m=0
								j=mod(j+1,PMT_BUFFER)
								continue
							endif
							if (flag2 == 1)
								PMTArrayValues[m] = PMTcounts[j]
								m += 1
							endif
							j=mod(j+1,PMT_BUFFER)
							n += 1
						while(m < 65 && n < PMT_BUFFER*2)	
						//Print "32-channel data acquired."
						return 0
					endif
				endfor
			endif
			k+=1
		endif
	while(1)

End

//_____________________________________________________________________________
//
// PMTArrayMonitor(maxCounts) continuously acquires PMT array data and displays it in a graph
//_____________________________________________________________________________
//
Function PMTArrayMonitor(maxCounts)

	Variable maxCounts	// Maximum counts on vertical graph axis
	Variable j
	Print "Hold ESC to stop."
	
	SetDataFolder root:PMT
	WAVE PMTArrayValues = PMTArrayValues
	MAKE/O/N=32 PMTArrayCounts
	// Execute "PMTMonitorGraph("+num2str(maxCounts)+")"	// Create graph of PMT count data using graph macro
	PMTArrayClose()		// Ensure PMT FPGA COM port is closed
	PMTArrayOpen()		// Open the COM port
		
	do
		PMTArrayPoll()	// Acquire the 32-channel count data
		for (j = 0; j < 32; j+=1)
			PMTArrayCounts[j] = PMTArrayValues[2*j]+PMTArrayValues[2*j+1]
		endfor
		DoUpdate		// Update graph
		if (GetKeyState(0) & 32) // Is Escape key pressed now?
			Print "ESC detected. Stopping..."
			break
		endif
	while(1)

	PMTArrayClose()		// Close PMT FPGA COM port
End

//_____________________________________________________________________________
//
//  PMTMonitorGraph(maxCounts) : Graph is a macro to display the PMT counts
//_____________________________________________________________________________
//
Window PMTMonitorGraph(maxCounts) : Graph
	Variable maxCounts // Maximum counts on vertical graph axis
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:PMT:
	DoWindow /F PMTMonitorGraph   // /F means 'bring to front if it exists'
		if (V_flag == 1)		// window does not exist
    			KillWindow PMTMonitorGraph
    		endif
	Display /W=(176.25,62,570.75,270.5) PMTArrayCounts
	SetDataFolder fldrSav0
	ModifyGraph mode=5
	ModifyGraph hbFill=2
	SetAxis left 0,maxCounts
EndMacro
