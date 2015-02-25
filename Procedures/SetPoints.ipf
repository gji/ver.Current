#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function DDS_wrapper(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	variable varNum

	SetDataFolder root:DDS
	Variable Frequency,Phase,Ampl
	WAVE DDS_INFO = root:ExpParams:DDS_INFO
	
	print ctrlName, varNum, varStr, varName
	
	strswitch(ctrlName)
		case "DDS1_FREQ_BOX":
			If(DDS_INFO[0][3])
				Frequency	=	DDS_INFO[0][0]*10^6
				Ampl		=	DDS_INFO[0][1]*1023/100
				Phase		=	DDS_INFO[0][2]
				setDDS(1,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS1_PHASE_BOX":
			If(DDS_INFO[0][3])
				Frequency	=	DDS_INFO[0][0]*10^6
				Ampl		=	DDS_INFO[0][1]*1023/100
				Phase		=	DDS_INFO[0][2]
				setDDS(1,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS1_AMPL_BOX":
			If(DDS_INFO[0][3])
				Frequency	=	DDS_INFO[0][0]*10^6
				Ampl		=	DDS_INFO[0][1]*1023/100
				Phase		=	DDS_INFO[0][2]
				setDDS(1,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS2_FREQ_BOX":
			If(DDS_INFO[1][3])
				Frequency	=	DDS_INFO[1][0]*10^6
				Ampl		=	DDS_INFO[1][1]*1023/100
				Phase		=	DDS_INFO[1][2]		
				setDDS(2,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS2_PHASE_BOX":
			If(DDS_INFO[1][3])
				Frequency	=	DDS_INFO[1][0]*10^6
				Ampl		=	DDS_INFO[1][1]*1023/100
				Phase		=	DDS_INFO[1][2]		
				setDDS(2,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS2_AMPL_BOX":
			If(DDS_INFO[1][3])
				Frequency	=	DDS_INFO[1][0]*10^6
				Ampl		=	DDS_INFO[1][1]*1023/100
				Phase		=	DDS_INFO[1][2]		
				setDDS(2,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS3_FREQ_BOX":
			If(DDS_INFO[2][3])
				Frequency	=	DDS_INFO[2][0]*10^6
				Ampl		=	DDS_INFO[2][1]*1023/100
				Phase		=	DDS_INFO[2][2]		
				setDDS(3,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS3_PHASE_BOX":
			If(DDS_INFO[2][3])
				Frequency	=	DDS_INFO[2][0]*10^6
				Ampl		=	DDS_INFO[2][1]*1023/100
				Phase		=	DDS_INFO[2][2]		
				setDDS(3,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS3_AMPL_BOX":
			If(DDS_INFO[2][3])
				Frequency	=	DDS_INFO[2][0]*10^6
				Ampl		=	DDS_INFO[2][1]*1023/100
				Phase		=	DDS_INFO[2][2]		
				setDDS(3,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS4_FREQ_BOX":
			If(DDS_INFO[3][3])
				Frequency	=	DDS_INFO[3][0]*10^6
				Ampl		=	DDS_INFO[3][1]*1023/100
				Phase		=	DDS_INFO[3][2]		
				setDDS(4,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS4_AMPL_BOX":
			If(DDS_INFO[3][3])
				Frequency	=	DDS_INFO[3][0]*10^6
				Ampl		=	DDS_INFO[3][1]*1023/100
				Phase		=	DDS_INFO[3][2]		
				setDDS(4,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS4_PHASE_BOX":
			If(DDS_INFO[3][3])
				Frequency	=	DDS_INFO[3][0]*10^6
				Ampl		=	DDS_INFO[3][1]*1023/100
				Phase		=	DDS_INFO[3][2]		
				setDDS(4,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS5_FREQ_BOX":
			If(DDS_INFO[4][3])
				Frequency	=	DDS_INFO[4][0]*10^6
				Ampl		=	DDS_INFO[4][1]*1023/100
				Phase		=	DDS_INFO[4][2]		
				setDDS(5,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS5_AMPL_BOX":
			If(DDS_INFO[4][3])
				Frequency	=	DDS_INFO[4][0]*10^6
				Ampl		=	DDS_INFO[4][1]*1023/100
				Phase		=	DDS_INFO[4][2]		
				setDDS(5,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS5_PHASE_BOX":
			If(DDS_INFO[4][3])
				Frequency	=	DDS_INFO[4][0]*10^6
				Ampl		=	DDS_INFO[4][1]*1023/100
				Phase		=	DDS_INFO[4][2]		
				setDDS(5,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS6_FREQ_BOX":
			If(DDS_INFO[4][3])
				Frequency	=	DDS_INFO[5][0]*10^6
				Ampl		=	DDS_INFO[5][1]*1023/100
				Phase		=	DDS_INFO[5][2]		
				setDDS(6,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS6_AMPL_BOX":
			If(DDS_INFO[5][3])
				Frequency	=	DDS_INFO[5][0]*10^6
				Ampl		=	DDS_INFO[5][1]*1023/100
				Phase		=	DDS_INFO[5][2]		
				setDDS(6,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS6_PHASE_BOX":
			If(DDS_INFO[5][3])
				Frequency	=	DDS_INFO[5][0]*10^6
				Ampl		=	DDS_INFO[5][1]*1023/100
				Phase		=	DDS_INFO[5][2]		
				setDDS(6,Frequency,Phase,Ampl)
			Endif
			break																		
	endswitch

end

function DDS_Overridewrapper(ctrlName,checked) : CheckBoxControl
	String ctrlName
	variable checked

	SetDataFolder root:DDS
	Variable Frequency,Phase,Ampl
	WAVE DDS_INFO = root:ExpParams:DDS_INFO
	
	strswitch(ctrlName)
		case "DDS1_Override":
			DDS_INFO[0][3]	= checked
			If(DDS_INFO[0][3])
				Frequency	=	DDS_INFO[0][0]*10^6
				Ampl		=	DDS_INFO[0][1]*1023/100
				Phase		=	DDS_INFO[0][2]
				setDDS(1,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS2_Override":
			DDS_INFO[1][3]	= checked
			If(DDS_INFO[1][3])
				Frequency	=	DDS_INFO[1][0]*10^6
				Ampl		=	DDS_INFO[1][1]*1023/100
				Phase		=	DDS_INFO[1][2]		
				setDDS(2,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS3_Override":
			DDS_INFO[2][3]	= checked
			If(DDS_INFO[2][3])
				Frequency	=	DDS_INFO[2][0]*10^6
				Ampl		=	DDS_INFO[2][1]*1023/100
				Phase		=	DDS_INFO[2][2]		
				setDDS(3,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS4_Override":
			DDS_INFO[3][3]	= checked
			If(DDS_INFO[3][3])
				Frequency	=	DDS_INFO[3][0]*10^6
				Ampl		=	DDS_INFO[3][1]*1023/100
				Phase		=	DDS_INFO[3][2]		
				setDDS(4,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS5_Override":
			DDS_INFO[4][3]	= checked
			If(DDS_INFO[4][3])
				Frequency	=	DDS_INFO[4][0]*10^6
				Ampl		=	DDS_INFO[4][1]*1023/100
				Phase		=	DDS_INFO[4][2]		
				setDDS(5,Frequency,Phase,Ampl)
			Endif
			break	
		case "DDS6_Override":
			DDS_INFO[5][3]	= checked
			If(DDS_INFO[5][3])
				Frequency	=	DDS_INFO[5][0]*10^6
				Ampl		=	DDS_INFO[5][1]*1023/100
				Phase		=	DDS_INFO[5][2]		
				setDDS(6,Frequency,Phase,Ampl)
			Endif
			break															
	endswitch
End

Function EO_OverrideWrapper(ctrlName,Checked) :CheckBoxControl
	String ctrlName
	variable checked
	
//	MMCInit

	SetDataFolder root:ExpParams
	Variable Frequency,Amplitude
	WAVE EO_INFO 
	
	strswitch(ctrlName)
		case "EO1_Override":
			EO_INFO[0][3]	= checked
			If(EO_INFO[0][3])
				Frequency=EO_INFO[0][1]
				Amplitude=EO_INFO[0][2]
				MMCSET/O=1/F=(Frequency)/P=(Amplitude) EO_INFO[0][0]
			Endif
			break
		case "EO2_Override":
			EO_INFO[1][3]	= checked
			If(EO_INFO[1][3])
				Frequency=EO_INFO[1][1]
				Amplitude=EO_INFO[1][2]
				MMCSET/O=1/F=(Frequency)/P=(Amplitude) EO_INFO[1][0]
			Endif
			break
		case "EO3_Override":
			EO_INFO[2][3]	= checked
			If(EO_INFO[2][3])
				Frequency=EO_INFO[2][1]
				Amplitude=EO_INFO[2][2]
				MMCSET/O=1/F=(Frequency)/P=(Amplitude) EO_INFO[2][0]
			Endif
			break			
	endswitch
	
	
End

function EO_wrapper(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	variable varNum

	SetDataFolder root:ExpParams
	Variable Frequency,Amplitude
	WAVE EO_INFO 
	
	strswitch(ctrlName)
		case "EO1_FREQ_BOX":
			EO_INFO[0][1]=varNum
			If(EO_INFO[0][3])
				Frequency=EO_INFO[0][1]
				Amplitude=EO_INFO[0][2]
				MMCSET/O=1/F=(Frequency)/P=(Amplitude) EO_INFO[0][0]
			Endif
			break
		case "EO1_AMPL_BOX":
			EO_INFO[0][2]=varNum
			If(EO_INFO[0][3])
				Frequency=EO_INFO[0][1]
				Amplitude=EO_INFO[0][2]
				MMCSET/O=1/F=(Frequency)/P=(Amplitude) EO_INFO[0][0]
			Endif
			break
		case "EO2_FREQ_BOX":
			EO_INFO[1][1]=varNum
			If(EO_INFO[1][3])
				Frequency=EO_INFO[1][1]
				Amplitude=EO_INFO[1][2]
				MMCSET/O=1/F=(Frequency)/P=(Amplitude) EO_INFO[1][0]
			Endif
			break
		case "EO2_AMPL_BOX":
			EO_INFO[1][2]=varNum	
			If(EO_INFO[1][3])
				Frequency=EO_INFO[1][1]
				Amplitude=EO_INFO[1][2]
				MMCSET/O=1/F=(Frequency)/P=(Amplitude) EO_INFO[1][0]
			Endif
			break
		case "EO3_FREQ_BOX":
			EO_INFO[2][1]=varNum
			If(EO_INFO[2][3])
				Frequency=EO_INFO[2][1]
				Amplitude=EO_INFO[2][2]
				MMCSET/O=1/F=(Frequency)/P=(Amplitude) EO_INFO[2][0]
			Endif
			break
		case "EO3_AMPL_BOX":
			EO_INFO[2][2]=varNum	
			If(EO_INFO[2][3])
				Frequency=EO_INFO[2][1]
				Amplitude=EO_INFO[2][2] 
				MMCSET/O=1/F=(Frequency)/P=(Amplitude) EO_INFO[2][0]
			Endif
			break						
	endswitch
end

function TTL_wrapper(ctrlName,checked)
	String ctrlName
	variable checked

	SetDataFolder root:ExpParams
	WAVE OverrideWave
	
//	String num, state
//	SplitString/E="TTL([0-9]+)_(Switch|Override)" ctrlName, num, state
//	
//	OverrideWave[str2num(num)-1][(StringMatch(state,"Switch"))?(0):(1)] = checked
//	UpdateTTL()
	
	strswitch(ctrlName)
		case "TTL1_Switch":
			OverrideWave[0][0]	= checked	
			OverrideWave[0][2]	= 1
			UpdateTTL()	
			break
		case "TTL2_Switch":
			OverrideWave[1][0]	= checked
			OverrideWave[1][2]	= 1
			UpdateTTL()	
			break
		case "TTL3_Switch":
			OverrideWave[2][0]	= checked
			OverrideWave[2][2]	= 1
			UpdateTTL()	
			break
		case "TTL4_Switch":
			OverrideWave[3][0]	= checked
			OverrideWave[3][2]	= 1
			UpdateTTL()	
			break
		case "TTL5_Switch":
			OverrideWave[4][0]	= checked
			OverrideWave[4][2]	= 1
			UpdateTTL()	
			break
		case "TTL6_Switch":
			OverrideWave[5][0]	= checked
			OverrideWave[5][2]	= 1
			UpdateTTL()	
			break
		case "TTL7_Switch":
			OverrideWave[6][0]	= checked
			OverrideWave[6][2]	= 1
			UpdateTTL()	
			break
		case "TTL8_Switch":
			OverrideWave[7][0]	= checked
			OverrideWave[7][2]	= 1
			UpdateTTL()	
			break
		case "TTL9_Switch":
			OverrideWave[8][0]	= checked
			OverrideWave[8][2]	= 1
			UpdateTTL()	
			break
		case "TTL10_Switch":
			OverrideWave[9][0]	= checked
			OverrideWave[9][2]	= 1
			UpdateTTL()	
			break
		case "TTL11_Switch":
			OverrideWave[10][0]	= checked
			OverrideWave[10][2]	= 1
			UpdateTTL()	
			break
		case "TTL15_Switch":
			OverrideWave[14][0]	= checked
			OverrideWave[14][2]	= 1
			UpdateTTL()	
			break	
		case "TTL16_Switch":
			OverrideWave[15][0]	= checked
			OverrideWave[15][2]	= 1
			UpdateTTL()	
			break		
		case "TTL1_Override":
			OverrideWave[0][1]	= checked
			OverrideWave[0][2]	= 2
			UpdateTTL()	
			break
		case "TTL2_Override":
			OverrideWave[1][1]	= checked
			OverrideWave[1][2]	= 2
			UpdateTTL()	
			break
		case "TTL3_Override":
			OverrideWave[2][1]	= checked
			OverrideWave[2][2]	= 2
			UpdateTTL()	
			break
		case "TTL4_Override":
			OverrideWave[3][1]	= checked
			OverrideWave[3][2]	= 2
			UpdateTTL()	
			break
		case "TTL5_Override":
			OverrideWave[4][1]	= checked
			OverrideWave[4][2]	= 2
			UpdateTTL()	
			break
		case "TTL6_Override":
			OverrideWave[5][1]	= checked
			OverrideWave[5][2]	= 2
			UpdateTTL()	
			break
		case "TTL7_Override":
			OverrideWave[6][1]	= checked
			OverrideWave[6][2]	= 2
			UpdateTTL()	
			break
		case "TTL8_Override":
			OverrideWave[7][1]	= checked
			OverrideWave[7][2]	= 2
			UpdateTTL()	
			break
		case "TTL9_Override":
			OverrideWave[8][1]	= checked
			OverrideWave[8][2]	= 2
			UpdateTTL()	
			break
		case "TTL10_Override":
			OverrideWave[9][1]	= checked
			OverrideWave[9][2]	= 2
			UpdateTTL()	
			break
		case "TTL11_Override":
			OverrideWave[10][1]	= checked
			OverrideWave[10][2]	= 2
			UpdateTTL()	
			break
		case "TTL15_Override":
			OverrideWave[14][1]	= checked
			OverrideWave[14][2]	= 2
			UpdateTTL()	
			break	
		case "TTL16_Override":
			OverrideWave[15][1]	= checked
			OverrideWave[15][2]	= 2
			UpdateTTL()	
			break		
		endswitch

end

Function UpdateTTL()
	SetDatafolder root:ExpParams
	WAVE OverrideWave
	NVAR Mask
	SVAR SEQ_PORT
	string seq_p = SEQ_PORT
	Make/O/N=(1,2) MaskWave
	String CreateMask
	Variable i=0
	Variable j=0
	Mask=0
	
	For(i=0; i<16; i+=1)

		If( OverrideWave[i][0])
			NVAR port = $("VAR_TTL_0"+num2str(i+1))
			print("Override TTL"+num2str(i+1)+" ON")
			Mask = Mask | port
		Elseif(OverrideWave[i][0]==0&&OverrideWave[i][2]==1)
			NVAR port = $("VAR_TTL_0"+num2str(i+1))
			print("Override TTL"+num2str(i+1)+" OFF")
		Elseif(OverrideWave[i][1] && OverrideWave[i][0]==0&&OverrideWave[i][2]==2)
			NVAR port = $("VAR_TTL_0"+num2str(i+1))
			print("Override TTL"+num2str(i+1)+" Overridden OFF")	
		Elseif(OverrideWave[i][1] && OverrideWave[i][0]&&OverrideWave[i][2]==2)
			NVAR port = $("VAR_TTL_0"+num2str(i+1))
			print("Override TTL"+num2str(i+1)+" Overridden ON")	
		Elseif(OverrideWave[i][1]==0 &&OverrideWave[i][2]==2)
			NVAR port = $("VAR_TTL_0"+num2str(i+1))
			print("Override TTL"+num2str(i+1)+" UNOverridden")				
		EndIf
	EndFor

	MaskWave={{Mask},{0x0000020}}

	sendSequence(MaskWave)
	runSequence(2)
	
End