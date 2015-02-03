#pragma rtGlobals=1		// Use modern global access method.

function setDDS(dds, frequency, phase, amplitude) // frequency in hertz!!
	Variable dds, frequency, phase, amplitude
	
	if(!(phase>=0))
		phase = 0
	endif
	//print dds, frequency, phase, amplitude
	
	SetDataFolder root:ExpParams
	SVAR DDS_PORT
	String dds_p = DDS_PORT
	
	Variable FTW = floor((2^(48))*(frequency / (10^9))) // Calculating frequency tuning word as per AD9912 manual
	Variable ap = amplitude*(2^(14)) + floor(45.5111*phase)  // Make amplitude/phase part
	Variable ddsNum = dds*2^1 + 1 // The 1 is for DDS enable
	
	Make/B/U/O writeWave = {0x71, ddsNum, 0x72, 0x00, gb_dds(ap,2), gb_dds(ap,1), gb_dds(ap,0), gb_dds(FTW,5), gb_dds(FTW,4), gb_dds(FTW,3), gb_dds(FTW,2), gb_dds(FTW,1), gb_dds(FTW,0), 0x0d, 0x0a, 0x6e, 0x01, 0x0d, 0x0a}
	// Check Verilog file for command documentation
	
	VDT2/P=$dds_p baud=230400,stopbits=2,killio
	VDTOpenPort2 $dds_p
	VDTOperationsPort2 $dds_p
	VDTWriteBinaryWave2 writeWave
	VDTClosePort2 $dds_p
	
	KillWaves writeWave
end

Function gb_dds(num, byte)
	Variable num, byte
	return floor(num / (256^(byte))) - 256*floor(num / (256^(byte+1)))
end

function setAll()
	Variable i
	for(i=1;i<=6;i+=1)
		setDDS(i,15000000,0,1023)
	endfor
end

function sweep()
	variable i;
	for(i=10;i<300;i+=10)
		setDDS(2, i*1000000, 0, 1023)
	endfor
end