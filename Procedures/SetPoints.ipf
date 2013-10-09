#pragma rtGlobals=3		// Use modern global access method and strict wave access.

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
		case "DDS3_FREQ_BOX":
			Frequency	=	DDS_INFO[1][0]*10^6
			Ampl		=	DDS_INFO[1][1]
			Phase		=	DDS_INFO[1][2]		
			setDDS(3,Frequency,Phase,Ampl)
			break
		case "DDS3_PHASE_BOX":
			Frequency	=	DDS_INFO[1][0]*10^6
			Ampl		=	DDS_INFO[1][1]
			Phase		=	DDS_INFO[1][2]		
			setDDS(3,Frequency,Phase,Ampl)
			break
		case "DDS3_AMPL_BOX":
			Frequency	=	DDS_INFO[1][0]*10^6
			Ampl		=	DDS_INFO[1][1]
			Phase		=	DDS_INFO[1][2]		
			setDDS(3,Frequency,Phase,Ampl)
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
			UpdateTTL()	
			break
		case "TTL2_Switch":
			OverrideWave[1][0]	= checked
			UpdateTTL()	
			break
		case "TTL3_Switch":
			OverrideWave[2][0]	= checked
			UpdateTTL()	
			break
		case "TTL4_Switch":
			OverrideWave[3][0]	= checked
			UpdateTTL()	
			break
		case "TTL5_Switch":
			OverrideWave[4][0]	= checked
			UpdateTTL()	
			break
		case "TTL6_Switch":
			OverrideWave[5][0]	= checked
			UpdateTTL()	
			break
		case "TTL7_Switch":
			OverrideWave[6][0]	= checked
			UpdateTTL()	
			break
		case "TTL8_Switch":
			OverrideWave[7][0]	= checked
			UpdateTTL()	
			break
		case "TTL1_Override":
			OverrideWave[0][1]	= checked
			UpdateTTL()	
			break
		case "TTL2_Override":
			OverrideWave[1][1]	= checked
			UpdateTTL()	
			break
		case "TTL3_Override":
			OverrideWave[2][1]	= checked
			UpdateTTL()	
			break
		case "TTL4_Override":
			OverrideWave[3][1]	= checked
			UpdateTTL()	
			break
		case "TTL5_Override":
			OverrideWave[4][1]	= checked
			UpdateTTL()	
			break
		case "TTL6_Override":
			OverrideWave[5][1]	= checked
			UpdateTTL()	
			break
		case "TTL7_Override":
			OverrideWave[6][1]	= checked
			UpdateTTL()	
			break
		case "TTL8_Override":
			OverrideWave[7][1]	= checked
			UpdateTTL()	
			break
		endswitch

end

Function UpdateTTL()
	SetDatafolder root:ExpParams
	WAVE OverrideWave
//	NVAR Mask // you can't use Mask during pulses if you want Off and Override
	NVAR Mask
	Make/O/N=(1,2) MaskWave
	String CreateMask
	Variable i=0
	Variable j=0
	Mask=0
//	Do
//		If (OverrideWave[i][1])
//			If(OverrideWave[i][0])
//				CreateMask="Mask=TTL_0"+num2str(OverrideWave[i][0])
//				j=i
//				Break
//			Endif
//		Endif
//		i+=1
//	While (i<8)
//	i=0
//	Do
//		If(OverrideWave[i][1])
//			If(OverrideWave[i][0])
//				If(i!=j)
//					CreateMask+="|TTL_0"+num2str(i)
//				Endif
//			Endif
//		Endif
//		i+=1
//	While (i<8)
//	
//	If(strlen(CreateMask))
//		Execute CreateMask
//		Print(Mask)
//		MaskWave={Mask,0x0000001}
//		sendSequence(MaskWave)
//		runSequence(1)
//	Endif
	
	For(i=0; i<8; i+=1)
		If(OverrideWave[i][1] && OverrideWave[i][0])
			NVAR port = $("VAR_TTL_0"+num2str(i+1))
			print("Override TTL"+num2str(port)+" ON")
			Mask = Mask | port
		EndIf
	EndFor
	
	sendSequence({Mask,0x0000001})
	runSequence(1)
	
End 

