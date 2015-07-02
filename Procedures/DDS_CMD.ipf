#pragma rtGlobals=1		// Use modern global access method.

function setDDS(dds, frequency, phase, amplitude) // frequency in hertz!!
	Variable dds, frequency, phase, amplitude
	
	if(!(phase>=0))
		phase = 0
	endif
	
	SetDataFolder root:ExpParams
	SVAR DDS_PORT
	String dds_p = DDS_PORT
	
	Variable FTW = floor((2^(48))*(frequency / (10^9))) // Calculating frequency tuning word as per AD9912 manual
	Variable ap = amplitude*(2^(14)) + floor(45.5111*phase)  // Make amplitude/phase part
	Variable ddsNum// = dds*2^1 + 1 // The 1 is for DDS enable
	
	//Make/B/U/O writeWave = {0x71, ddsNum, 0x72, 0x00, gb_dds(ap,2), gb_dds(ap,1), gb_dds(ap,0), gb_dds(FTW,5), gb_dds(FTW,4), gb_dds(FTW,3), gb_dds(FTW,2), gb_dds(FTW,1), gb_dds(FTW,0), 0x0d, 0x0a, 0x6e, 0x01, 0x0d, 0x0a}
	// Check Verilog file for command documentation
	If(DDS==1||DDS==2||DDS==3||DDS==4||DDS==5||DDS==6)
		ddsNum = dds*2^1 + 1 // The 1 is for DDS enable
		Make/B/U/O writeWave = {0x71, ddsNum, 0x72, 0x00, gb_dds(ap,2), gb_dds(ap,1), gb_dds(ap,0), gb_dds(FTW,5), gb_dds(FTW,4), gb_dds(FTW,3), gb_dds(FTW,2), gb_dds(FTW,1), gb_dds(FTW,0), 0x0d, 0x0a, 0x6e, 0x01, 0x0d, 0x0a}
		VDT2/P=COM5 baud=230400,stopbits=2,killio
		VDTOpenPort2 COM5
		VDTOperationsPort2 COM5
		VDTWriteBinaryWave2 writeWave
		VDTClosePort2 COM5

	elseif(DDS==7||DDS==8||DDS==9||DDS==10||DDS==11||DDS==12)
		ddsNum = (dds-6)*2^1 + 1 // The 1 is for DDS enable
		Make/B/U/O writeWave = {0x71, ddsNum, 0x72, 0x00, gb_dds(ap,2), gb_dds(ap,1), gb_dds(ap,0), gb_dds(FTW,5), gb_dds(FTW,4), gb_dds(FTW,3), gb_dds(FTW,2), gb_dds(FTW,1), gb_dds(FTW,0), 0x0d, 0x0a, 0x6e, 0x01, 0x0d, 0x0a}			
		VDT2/P=COM10 baud=230400,stopbits=2,killio
		VDTOpenPort2 COM10
		VDTOperationsPort2 COM10
		VDTWriteBinaryWave2 writeWave
		VDTClosePort2 COM10
	endif
	KillWaves writeWave
end

// WARNING: this function assumes dds > 6, i.e. we are addressing the new dds box with sequence support
function setDDSSeq(dds, info)  // info is a wave with columns frequency, phase, amplitude
	Variable dds
	Wave info

	Make/B/U/O/N=0 out
	Variable i=0;
	for(i=0; i<DimSize(info, 0); i+=1)
		Wave t = ddsCmdStr(mod(dds-1,6)+1, i, info[i][0], info[i][1], info[i][2])
		Concatenate/NP {t}, out
		if(i>0 && dds <= 6)
			Abort "Cannot trigger on DDS <= 6!"
		endif
	endfor
	Make/B/U/O lines = {0x6e, gb_dds(DimSize(info, 0), 0), 0x0d, 0x0a}
	Concatenate/NP {lines}, out
	if(dds > 6)
		VDT2/P=COM10 baud=230400,stopbits=2,killio
		VDTOpenPort2 COM10
		VDTOperationsPort2 COM10
		VDTWriteBinaryWave2 out
		VDTClosePort2 COM10
	else
		VDT2/P=COM5 baud=230400,stopbits=2,killio
		VDTOpenPort2 COM5
		VDTOperationsPort2 COM5
		VDTWriteBinaryWave2 out
		VDTClosePort2 COM5
	endif
	KillWaves out
end

function/WAVE ddsCmdStr(dds, id, frequency, phase, amplitude)
	Variable dds, id, frequency, phase, amplitude
	
	if(!(phase>=0))
		phase = 0
	endif
	
	Variable FTW = floor((2^(48))*(frequency / (10^9))) // Calculating frequency tuning word as per AD9912 manual
	Variable ap = amplitude*(2^(14)) + floor(45.5111*phase)  // Make amplitude/phase part

	Variable ddsNum = dds*2^1 + 1 // The 1 is for DDS enable
	Make/B/U/O writeWave = {0x71, ddsNum, 0x72, gb_dds(id, 0), gb_dds(ap,2), gb_dds(ap,1), gb_dds(ap,0), gb_dds(FTW,5), gb_dds(FTW,4), gb_dds(FTW,3), gb_dds(FTW,2), gb_dds(FTW,1), gb_dds(FTW,0), 0x0d, 0x0a}
	return writeWave
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