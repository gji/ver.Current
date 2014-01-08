#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function DDS_wrapper(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	variable varNum

	SetDataFolder root:DDS
	Variable Frequency,Phase,Ampl
	WAVE DDS_INFO = root:ExpParams:DDS_INFO
	
	strswitch(ctrlName)
		case "DDS1_FREQ_BOX":
			If(DDS_INFO[0][3])
				Frequency	=	DDS_INFO[0][0]*10^6
				Ampl		=	DDS_INFO[0][1]
				Phase		=	DDS_INFO[0][2]
				setDDS(1,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS1_PHASE_BOX":
			If(DDS_INFO[0][3])
				Frequency	=	DDS_INFO[0][0]*10^6
				Ampl		=	DDS_INFO[0][1]
				Phase		=	DDS_INFO[0][2]
				setDDS(1,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS1_AMPL_BOX":
			If(DDS_INFO[0][3])
				Frequency	=	DDS_INFO[0][0]*10^6
				Ampl		=	DDS_INFO[0][1]
				Phase		=	DDS_INFO[0][2]
				setDDS(1,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS2_FREQ_BOX":
			If(DDS_INFO[1][3])
				Frequency	=	DDS_INFO[1][0]*10^6
				Ampl		=	DDS_INFO[1][1]
				Phase		=	DDS_INFO[1][2]		
				setDDS(2,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS2_PHASE_BOX":
			If(DDS_INFO[1][3])
				Frequency	=	DDS_INFO[1][0]*10^6
				Ampl		=	DDS_INFO[1][1]
				Phase		=	DDS_INFO[1][2]		
				setDDS(2,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS2_AMPL_BOX":
			If(DDS_INFO[1][3])
				Frequency	=	DDS_INFO[1][0]*10^6
				Ampl		=	DDS_INFO[1][1]
				Phase		=	DDS_INFO[1][2]		
				setDDS(2,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS3_FREQ_BOX":
			If(DDS_INFO[2][3])
				Frequency	=	DDS_INFO[1][0]*10^6
				Ampl		=	DDS_INFO[1][1]
				Phase		=	DDS_INFO[1][2]		
				setDDS(3,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS3_PHASE_BOX":
			If(DDS_INFO[2][3])
				Frequency	=	DDS_INFO[1][0]*10^6
				Ampl		=	DDS_INFO[1][1]
				Phase		=	DDS_INFO[1][2]		
				setDDS(3,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS3_AMPL_BOX":
			If(DDS_INFO[2][3])
				Frequency	=	DDS_INFO[1][0]*10^6
				Ampl		=	DDS_INFO[1][1]
				Phase		=	DDS_INFO[1][2]		
				setDDS(3,Frequency,Phase,Ampl)
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
				Ampl		=	DDS_INFO[0][1]
				Phase		=	DDS_INFO[0][2]
				setDDS(1,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS2_Override":
			DDS_INFO[1][3]	= checked
			If(DDS_INFO[1][3])
				Frequency	=	DDS_INFO[1][0]*10^6
				Ampl		=	DDS_INFO[1][1]
				Phase		=	DDS_INFO[1][2]		
				setDDS(2,Frequency,Phase,Ampl)
			Endif
			break
		case "DDS3_Override":
			DDS_INFO[2][3]	= checked
			If(DDS_INFO[2][3])
				Frequency	=	DDS_INFO[1][0]*10^6
				Ampl		=	DDS_INFO[1][1]
				Phase		=	DDS_INFO[1][2]		
				setDDS(3,Frequency,Phase,Ampl)
			Endif							
	endswitch
End

Function EO_OverrideWrapper(ctrlName,Checked) :CheckBoxControl
	String ctrlName
	variable checked

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
			EO_INFO[0][1]=varNum*10^6
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
			EO_INFO[1][1]=varNum*10^6	
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
			EO_INFO[2][1]=varNum*10^6	
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

		If(OverrideWave[i][1] && OverrideWave[i][0]&&OverrideWave[i][2]==1)
			NVAR port = $("VAR_TTL_0"+num2str(i+1))
			print("Override TTL"+num2str(i+1)+" ON")
			Mask = Mask | port
		Elseif(OverrideWave[i][1] && OverrideWave[i][0]==0&&OverrideWave[i][2]==1)
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

	MaskWave={Mask,0x0000020}
	
	
	sendSequence(MaskWave)
	runSequence(1)
	
	
	
End 


Function TestPrint2ALL(in)
	WAVE in
	Variable i=0
	Variable ii=0
	Variable row= dimsize(in,0)
	Variable col= dimsize(in,1)
	
	For(i=0;i<row;i+=1)
		For(ii=0;ii<col;ii+=1)
			Print(in[i][ii])
		Endfor
	Endfor
End

Function TestPrint4All(in)
	WAVE in
	Variable i=0
	Variable ii=0
	Variable iii=0
	Variable iiii=0
	Variable row= dimsize(in,0)
	Variable col= dimsize(in,1)
	Variable layer=dimsize(in,2)
	Variable chunk=dimsize(in,3)
	
	For(i=0;i<row;i+=1)
		For(ii=0;ii<col;ii+=1)
				
			For(iii=0;iii<layer;iii+=1)
			Print ("coords: "+num2str(i)+", "+num2str(ii)+", "+num2str(iii))
				for(iiii=0;iiii<chunk;iiii+=1)
					Print(in[i][ii][iii][iiii])
				Endfor
			Endfor
		Endfor
	Endfor
End
Function TestPrint1ALL(in)
	WAVE in
	Variable i=0
	Variable row= dimsize(in,0)

	
	For(i=0;i<row;i+=1)

			Print(in[i])

	Endfor
End