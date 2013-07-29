#pragma rtGlobals=1		// Use modern global access method.
#include <NIDAQmxWaveFormGenProcs>

//--------------------------------------------------------------
//
//                        UI Listeners
//
//--------------------------------------------------------------

// Open Buttons in DC Voltage Settings pane
Function OpenWaveFile(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SetDataFolder root:ExpParams	
	
	NVAR		LIVE_UP
	WAVE		COMP_INFO
	WAVE/T		WAVE_INFO
	
	String lookup = "zxyhu"
	
	Switch( ba.eventCode )
		Case 2:
			Variable ctrlNum = strsearch(lookup,num2char(ba.ctrlName[0]),0)
			If(ctrlNum == 4)
				LoadDCWaveMatricies()
//				upPos(vals[5],0)
				If(LIVE_UP)
					updateVoltages()
				EndIf
				Break
			EndIf
			Variable refNum
			
			Open /D/P=home /R /F="All Files:.*;" /M="Select a file" refNum
			WAVE_INFO[ctrlNum] = S_fileName

			Break
		Case -1:
			Break
	EndSwitch

	Return 0
End

// Settings button
Function openSettings(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	Switch( ba.eventCode )
		Case 2:
		String windows = WinList("DCSettings", ";", "")
		If(strlen(windows)>0)
			DoWindow/K DCSettings
		Else
			GetWindow DCCtrl wsizeOuter
			Execute "DCSettings(" + num2str(V_left*4/3) + "," + num2str(V_right*4/3) + "," + num2str(V_top*4/3) + "," + num2str(V_bottom*4/3) +")"
		EndIf
		Break
		Case -1:
			Break
	EndSwitch
EndMacro

//	Text box for fields
Function fieldUpdate(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	SetDataFolder root:ExpParams
	NVAR LIVE_UP
	WAVE COMP_INFO

	Switch( sva.eventCode )
		Case 1: // mouse up
		Case 2: // Enter key
		Case 3: // Live update
			
			If(LIVE_UP)
				updateVoltages()
			EndIf
			Break
		Case -1: // control being killed
			Break
	EndSwitch

	Return 0
End

//// +/- buttons for fields
function ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	SetDataFolder root:DCVolt
	WAVE COMP_INFO		=	root:ExpParams:COMP_INFO
	WAVE FIELDS
	
	NVAR LIVE_UP			=	root:ExpParams:LIVE_UP

	STRING lookup = "zxyhgp"

	Switch( ba.eventCode )
		Case 2:
			Variable ctrlNum = strsearch(lookup,num2char(ba.ctrlName[0]),0)
			Variable curVal = COMP_INFO[ctrlNum];
			If (ctrlNum!=5)
			
				If ( stringmatch(num2char(ba.ctrlName[4]), "p") )
					COMP_INFO[ctrlNum] = round(curVal*100+1)/100
				Else
					COMP_INFO[ctrlNum] = round(curVal*100-1)/100
				EndIf
			Else
//				upPos(vals[ctrlNum],(stringmatch(num2char(ba.ctrlName[4]), "p"))?(1):(-1))
			EndIf
			If(LIVE_UP)
				updateVoltages()
			EndIf
			Break
		Case -1:
			Break
	EndSwitch

	Return 0
End

// Live Update checkbox (applies to update field waves in settings pane as well!!)
Function LiveUpCheck(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	SetDataFolder root:ExpParams

	NVAR LIVE_UP

	Switch( cba.eventCode )
		Case 2: // mouse up
			//Variable checked = cba.checked
			If(cba.checked)
				Button update disable=2
				LIVE_UP = 1
			Else
				Button update disable=0
				LIVE_UP = 0
			EndIf
			Break
		Case -1: // control being killed
			Break
	EndSwitch

	Return 0
End

// Manual update button
Function Update(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	SetDataFolder root:DCVolt

	Switch( ba.eventCode )
		Case 2: // mouse up
			updateVoltages()
			Break
		Case -1: // control being killed
			Break
	EndSwitch

	Return 0
End

//--------------------------------------------------------------
//
//                    UI Helper Functions
//
//--------------------------------------------------------------

//// Updates position, moving ion position up, direction=1; down, direction=-1; nowhere, otherwise
//Function upPos( direction)
//	SetDataFolder root:DCVolt	
//	NVAR CUR_POS		=	root:ExpParams:CUR_POS
//
//	Wave vals
//	Wave fields
//	
//	Wave tmat = $("mat0")
//	FindValue/V=(curPos) tmat
//	if ( direction == 1 )
//		curPos = tmat[V_Value+1]
//	elseif (direction == -1)
//		curPos = tmat[V_Value-1]
//	endif
//	vals[5]=curPos
//	
//	Variable i
//	for(i=0; i<4; i+=1)
//		Wave tmat = $("mat" + num2str(i))
//		FindValue/V=(vals[5]) tmat
//		fields[][i] = tmat[V_Value][p+1]
//	endfor
//End

function updateVoltages()
	SetDataFolder root:DCVolt
	
	WAVE COMP_INFO		=	root:ExpParams:COMP_INFO
	WAVE FIELDS
	WAVE RAW_VOLTAGES
	
	NVAR CUR_POS			=	root:ExpParams:CUR_POS
	NVAR NUM_ELECT
	Variable i	
	
	RAW_VOLTAGES		= 0
//	VARIABLE	j			= 0
//	WAVE tmat = $("mat0")		
//	FindValue/V=(0) tmat	
//	variable d
//	d	=	tmat[V_Value+1]-tmat[V_Value]
//	print d	
//	Do 
//		j = mod(CUR_POS,d)			
//		if(j>d/2)
//			CUR_POS	+=d-j
//		else	
//			CUR_POS	+=	j
//		endif	
//	while (j)	
//	FindValue/V=(CUR_POS) tmat
//	VARIABLE	k	=	V_Value-1
//	interp

	For(i=0; i<DimSize(COMP_INFO,0)-1;i+=1)		
		//WAVE tmat = $("mat0")	
		WAVE tmat = $("mat" + num2str(i))
		
		//WAVE
//		FindValue/V=(CUR_POS) tmat
//		variable k = v_value
//		if (k	==	-1)
//			print "DC Update error"
//			print k
//			print CUR_POS+i							
//			return -1
//		elseif(k > 0)
//			FIELDS[][i] = tmat[k][p+1]
//		endif
		// A temporary array to store the individual columns of tmat, minus the position column
		Make/O/N=(Dimsize(tmat,0)) temp
		FindLevel/Q tmat, CUR_POS
		if(V_LevelX >= Dimsize(tmat,0) || V_LevelX < 0)
			print "DC Update Error!"
			print "Could not find level \""+ num2str(CUR_POS) + "\", got \"" + num2str(V_LevelX) + "\""
			return -1
		else
			Variable j
			For(j=1; j<Dimsize(tmat,1);j+=1) // Start at second column since first column is position
				temp[] = tmat[p][j] // Fill temp with the right column
				// The index below is corrected for the position column
				FIELDS[j-1][i] = temp(V_LevelX) // Igor will automatically interpolate a 1D wave.
			EndFor
		endif
		//KillWaves temp, tempX
		
		RAW_VOLTAGES[]	+= COMP_INFO[i] * FIELDS[p][i]
	EndFor
	
	RAW_VOLTAGES		*= COMP_INFO[4]
	
	sendVoltageGroup(RAW_VOLTAGES)
End

//--------------------------------------------------------------
//
//                   COMMUNICATION FUNCTIONS
//
//--------------------------------------------------------------

Function sendVoltageGroup(RAW_VOLTAGES)
	WAVE		RAW_VOLTAGES
	WAVE/T		HARDWARE_MAP	=	root:ExpParams:HARDWARE_MAP	
	WAVE		OUT_VOLTAGES	
	WAVE/T		CMDS	
	
	NVAR		NUM_ELECT			
	
	Variable 		i
	
	For(i=0;i<12;i+=1)
		CMDS[i]=""
	EndFor
	
	For(i=0;i<96;i+=1)
		FindValue/TEXT=num2str(i+1)/TXOP=4 HARDWARE_MAP
		if(V_Value < NUM_ELECT)
			OUT_VOLTAGES[i] = RAW_VOLTAGES[V_Value]
		EndIf
	EndFor
	
	//
	overVoltWarning(OUT_VOLTAGES)
	//
	
	For(i=0;i<96;i+=1)
		CMDS[floor(i/8)] += num2str(OUT_VOLTAGES[i]) + "," + num2str(i-8*floor(i/8)) + ";"
	EndFor
	
	For(i=0;i<12;i+=1)
		DAQmx_AO_SetOutputs /KEEP=1/DEV="D"+num2str(i+1) CMDS[i]
	EndFor
End

//
Function overVoltWarning(OUT_VOLTAGES)
	WAVE		OUT_VOLTAGES
	Variable voltCap
	Variable i
	voltCap = 10
	i = 0
	For(i=0;i<96;i+=1)
		if(OUT_VOLTAGES[i] >= voltCap)
			
			Abort "Exceeded 10 Volts"
	
		EndIf
	EndFor
	
		
END
//
//Test Functions//

Function Scan_l(k,COMP_INFO,Holder,Scale,Step, Wait)
	Variable k
	WAVE COMP_INFO
	WAVE	Holder
	Variable Scale
	Variable Step
	Variable Wait
	
	Variable l
	

	if (round(mod(abs(((k-Holder[1])/Step)),2)) != 1)
		
		
		For(l= Holder[0]- Scale;l<=Holder[0] + Scale  ;l+=Step)
								
					COMP_INFO[0]	=	l
					Print COMP_INFO					
					updateVoltages()
					DoUpdate
					Sleep/s/B Wait
		EndFor
	else
	
	
		For(l= Holder[0]+ Scale;l>=Holder[0] - Scale  ;l-=Step)
								
					COMP_INFO[0]	=	l
					Print COMP_INFO					
					updateVoltages()
					DoUpdate
					Sleep/s/B Wait
		EndFor
	EndIf
	
		

END

Function Scan_k(j,COMP_INFO,Holder,Scale,Step, Wait)
	Variable j
	WAVE		COMP_INFO
	WAVE		Holder
	

	Variable Scale
	Variable Step
	Variable Wait
	
	Variable k

	if (round(mod(abs(((j-Holder[2])/Step)),2)) != 1)
		For(k= Holder[1]- Scale;k<=Holder[1] + Scale  ;k+=Step)
								
					COMP_INFO[1]	=	k
					Print COMP_INFO					
					updateVoltages()
					DoUpdate
					Sleep/s/B Wait
					Scan_l(k,COMP_INFO,Holder,Scale,Step,Wait)
		EndFor
	else
		For(k= Holder[1]+ Scale;k>=Holder[1] - Scale ;k-=Step)
								
					COMP_INFO[1]	=	k
					Print COMP_INFO					
					updateVoltages()
					DoUpdate
					Sleep/s/B Wait
					Scan_l(k,COMP_INFO,Holder,Scale,Step,Wait)
		EndFor
	EndIf
	
		

END

Function Scan_j(i,COMP_INFO,Holder,Scale,Step, Wait)
	Variable i
	WAVE		COMP_INFO
	WAVE		Holder
	

	Variable Scale
	Variable Step
	Variable Wait
	
	Variable j
	

	if (round(mod(abs(((i-Holder[3])/Step)),2)) != 1)
		For(j= Holder[2]- Scale;j<=Holder[2] + Scale  ;j+=Step)
								
					COMP_INFO[2]	=	j
					Print COMP_INFO					
					updateVoltages()
					DoUpdate
					Sleep/s/B Wait
					Scan_k(j,COMP_INFO,Holder,Scale,Step,Wait)
		EndFor
	else
		For(j= Holder[2]+ Scale;j>=Holder[2] - Scale ;j-=Step)
								
					COMP_INFO[2]	=	j
					Print COMP_INFO					
					updateVoltages()
					DoUpdate
					Sleep/s/B Wait
					Scan_k(j,COMP_INFO,Holder,Scale,Step,Wait)
		EndFor
	EndIf
	
		

END


Function LoadParamScan()
	WAVE COMP_INFO	=	root:ExpParams:COMP_INFO
	
	Variable Scale	=	1
	Variable Step	=	0.2
	Variable Wait 	=	10
	Make/O/N=4 Holder	= COMP_INFO
	Variable i
	
	Variable stepNumber = round(Scale/Step)
	
	For (i = Holder[3] - Scale; i <= Holder[3] +Scale; i+= Step)
		COMP_INFO[3]	=	i
		Print COMP_INFO					
		updateVoltages()
		DoUpdate
		Sleep/s/B Wait
		Scan_j(i,COMP_INFO,Holder,Scale,Step, Wait) 
	EndFor
End		


//

//Function Stop()
//	Make/T/O/N=12 cmds
//	Variable i
//	for(i=0;i<12;i+=1)
//		cmds[i]=""
//	endfor
//	for(i=0;i<96;i+=1)
//		cmds[floor(i/8)] += "0" + "," + num2str(i-8*floor(i/8)) + ";"
//	endfor
//	for(i=0;i<12;i+=1)
//		DAQmx_AO_SetOutputs /KEEP=1/DEV="D"+num2str(i+1) cmds[i]
//	endfor
//End
//
//Function Test()
//	Make/T/O/N=12 cmds
//	Variable i
//	for(i=0;i<12;i+=1)
//		cmds[i]=""
//	endfor
//	for(i=0;i<96;i+=1)
//		cmds[floor(i/8)] += num2str(i/10) + "," + num2str(i-8*floor(i/8)) + ";"
//	endfor
//	for(i=0;i<12;i+=1)
//		DAQmx_AO_SetOutputs /KEEP=1/DEV="D"+num2str(i+1) cmds[i]
//	endfor
//End























































