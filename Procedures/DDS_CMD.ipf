#pragma rtGlobals=1		// Use modern global access method.

function DDS_wrapper(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	variable varNum

	SetDataFolder root:DDS
	Variable Frequency,Phase,Ampl
	WAVE DDS_INFO = root:ExpParams:DDS_INFO
	
	strswitch(ctrlName)
		case "DDS1_FREQ_BOX":
			Frequency	=	DDS_INFO[0][0]*10^6
			Ampl		=	DDS_INFO[0][1]
			Phase		=	DDS_INFO[0][2]
			setDDS(1,Frequency,Phase,Ampl)
			break
		case "DDS1_PHASE_BOX":
			Frequency	=	DDS_INFO[0][0]*10^6
			Ampl		=	DDS_INFO[0][1]
			Phase		=	DDS_INFO[0][2]
			setDDS(1,Frequency,Phase,Ampl)
			break
		case "DDS1_AMPL_BOX":
			Frequency	=	DDS_INFO[0][0]*10^6
			Ampl		=	DDS_INFO[0][1]
			Phase		=	DDS_INFO[0][2]
			setDDS(1,Frequency,Phase,Ampl)
			break
		case "DDS2_FREQ_BOX":
			Frequency	=	DDS_INFO[1][0]*10^6
			Ampl		=	DDS_INFO[1][1]
			Phase		=	DDS_INFO[1][2]		
			setDDS(2,Frequency,Phase,Ampl)
			break
		case "DDS2_PHASE_BOX":
			Frequency	=	DDS_INFO[1][0]*10^6
			Ampl		=	DDS_INFO[1][1]
			Phase		=	DDS_INFO[1][2]		
			setDDS(2,Frequency,Phase,Ampl)
			break
		case "DDS2_AMPL_BOX":
			Frequency	=	DDS_INFO[1][0]*10^6
			Ampl		=	DDS_INFO[1][1]
			Phase		=	DDS_INFO[1][2]		
			setDDS(2,Frequency,Phase,Ampl)
			break										
	endswitch

end

function setDDS(dds, frequency, phase, amplitude)
	Variable dds, frequency, phase, amplitude
	
	Variable FTW = floor((2^(48))*(frequency / (10^9))) // Calculating frequency tuning word as per AD9912 manual
	Variable ap = amplitude*(2^(14)) + floor(45.5111*phase)  // Make amplitude/phase part
	Variable ddsNum = dds*2^1 + 1 // The 1 is for DDS enable
	
	Make/B/U/O writeWave = {0x71, ddsNum, 0x72, 0x00, gb_dds(ap,2), gb_dds(ap,1), gb_dds(ap,0), gb_dds(FTW,5), gb_dds(FTW,4), gb_dds(FTW,3), gb_dds(FTW,2), gb_dds(FTW,1), gb_dds(FTW,0), 0x0d, 0x0a, 0x6e, 0x01, 0x0d, 0x0a}
	// Check Verilog file for command documentation
	
	VDTOperationsPort2 COM8
	VDTWriteBinaryWave2 writeWave
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