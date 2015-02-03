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
	
	String lookup = "abcdehwu"
	
	Switch( ba.eventCode )
		Case 2:
			Variable ctrlNum = strsearch(lookup,num2char(ba.ctrlName[0]),0)
			If(ctrlNum == 7) // Update
				LoadDCWaveMatrices()
				If(LIVE_UP)
					updateVoltages()
				EndIf
				Break // Get out of here before file selection box opens
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
			print "DCSettings(" + num2str(V_left*4/3) + "," + num2str(V_right*4/3) + "," + num2str(V_top*4/3) + "," + num2str(V_bottom*4/3) +")"
			//Execute "DCSettings(" + num2str(V_left*4/3) + "," + num2str(V_right*4/3) + "," + num2str(V_top*4/3) + "," + num2str(V_bottom*4/3) +")"
			Execute "DCSettings()"
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
	
	STRING lookup = "abcdehgp"

	Switch( sva.eventCode )
		Case 1: // mouse up
		Case 2: // Enter key
		Case 3: // Live update
			Variable ctrlNum = strsearch(lookup,num2char(sva.ctrlName[0]),0)
			Variable curVal = COMP_INFO[ctrlNum];
			If (ctrlNum!=7)
				COMP_INFO[ctrlNum] = round(COMP_INFO[ctrlNum]*100)/100
			EndIf

			If(LIVE_UP)
				updateVoltages()
			EndIf
			Break
		Case -1: // control being killed
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

Function HoldUpCheck(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	SetDataFolder root:ExpParams

	NVAR HOLD_UP

	Switch( cba.eventCode )
		Case 2: // mouse up
			//Variable checked = cba.checked
			If(cba.checked)
				SetVariable apos_1,disable=0
				SetVariable bpos_1,disable=0
				SetVariable cpos_1,disable=0
				SetVariable dpos_1,disable=0
				SetVariable epos_1,disable=0
				SetVariable harmScale_1,disable=0
				SetVariable globScale_1,disable=0
				SetVariable posIon_1,disable=0
				Button MergeToHold,disable=0	
				HOLD_UP = 1
			Else
				SetVariable apos_1,disable=2
				SetVariable bpos_1,disable=2
				SetVariable cpos_1,disable=2
				SetVariable dpos_1,disable=2
				SetVariable epos_1,disable=2
				SetVariable harmScale_1,disable=2
				SetVariable globScale_1,disable=2
				SetVariable posIon_1,disable=2
				Button MergeToHold,disable=2		
				HOLD_UP = 0
			EndIf
			Break
		Case -1: // control being killed
			Break
	EndSwitch

	Return 0
End

Function LoadUpCheck(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	SetDataFolder root:ExpParams

	NVAR LOAD_UP

	Switch( cba.eventCode )
		Case 2: // mouse up
			//Variable checked = cba.checked
			If(cba.checked)
				SetVariable apos_2,disable=0
				SetVariable bpos_2,disable=0
				SetVariable cpos_2,disable=0
				SetVariable dpos_2,disable=0
				SetVariable epos_2,disable=0
				SetVariable harmScale_2,disable=0
				SetVariable globScale_2,disable=0
				SetVariable posIon_2,disable=0
				Button MergeToLoad,disable=0					
				LOAD_UP = 1
			Else
				SetVariable apos_2,disable=2
				SetVariable bpos_2,disable=2
				SetVariable cpos_2,disable=2
				SetVariable dpos_2,disable=2
				SetVariable epos_2,disable=2
				SetVariable harmScale_2,disable=2
				SetVariable globScale_2,disable=2
				SetVariable posIon_2,disable=2
				Button MergeToLoad,disable=2					
				LOAD_UP = 0
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

Function MergeToHold(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	SetDataFolder root:DCVolt

	Switch( ba.eventCode )
		Case 2: // mouse up
			mergeToHoldVoltages()
			Break
		Case -1: // control being killed
			Break
	EndSwitch

	Return 0
End

Function MergeToLoad(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	SetDataFolder root:DCVolt

	Switch( ba.eventCode )
		Case 2: // mouse up
			mergeToLoadVoltages()
			Break
		Case -1: // control being killed
			Break
	EndSwitch

	Return 0
End

Function DCBankProc(name,value)
	String name
	Variable value
	
	SetDataFolder root:ExpParams
	
	NVAR DC_BANK_VAL
	
	switch (DC_BANK_VAL)
		case 1:
			Duplicate/O WAVE_INFO, WAVE_INFOa
			break
		case 2:
			Duplicate/O WAVE_INFO, WAVE_INFOb
			break
		case 3:
			Duplicate/O WAVE_INFO, WAVE_INFOc
			break
	endswitch
	
	strswitch (name)
		case "abank":
			DC_BANK_VAL= 1
			Duplicate/O WAVE_INFOa, WAVE_INFO
			break
		case "bbank":
			DC_BANK_VAL= 2
			Duplicate/O WAVE_INFOb, WAVE_INFO
			break
		case "cbank":
			DC_BANK_VAL= 3
			Duplicate/O WAVE_INFOc, WAVE_INFO
			break
	endswitch
	CheckBox abank,value= DC_BANK_VAL==1
	CheckBox bbank,value= DC_BANK_VAL==2
	CheckBox cbank,value= DC_BANK_VAL==3
End

//--------------------------------------------------------------
//
//                    UI Helper Functions
//
//--------------------------------------------------------------


// This function uses basic 2-point linear interpolation for positions not given voltages
function updateVoltages()
	SetDataFolder root:DCVolt
	
	WAVE COMP_INFO		=	root:ExpParams:COMP_INFO
	WAVE FIELDS
	WAVE RAW_VOLTAGES
	WAVE HOLD_VOLTAGES
	WAVE LOAD_VOLTAGES
	WAVE MOVE_VOLTAGES
	
	
	NVAR CUR_POS			=	root:ExpParams:CUR_POS
	NVAR MOV_POS		=	root:ExpParams:MOV_POS	
	NVAR HOLD_UP			=	root:ExpParams:HOLD_UP
	NVAR LOAD_UP			=	root:ExpParams:LOAD_UP	
	NVAR NUM_ELECT
	Variable i
	Variable j
	
	HOLD_VOLTAGES=0
	LOAD_VOLTAGES=0
//	if(HOLD_UP)
//		holdVoltages()
//	else
//		HOLD_VOLTAGES=0
//	endif
//	if(LOAD_UP)
//		loadVoltages()
//	else
//		LOAD_VOLTAGES=0
//	endif
	MOVE_VOLTAGES		= 0
	if((abs(mov_pos-cur_pos)<50)||HOLD_UP)
		For(i=0; i<6;i+=1)  // There are 6 different waveforms
			WAVE tmat = $("mat" + num2str(i))
			if(!WaveExists(tmat))
				FIELDS[][i] = 0
				continue
			endif
			// A temporary array to store the individual columns of tmat, minus the position column
			Make/O/N=(Dimsize(tmat,0)) temp
			FindLevel/Q tmat, MOV_POS
			if(V_LevelX >= Dimsize(tmat,0) || V_LevelX < 0)
				print "DC Update Error!"
				print "Could not find level \""+ num2str(MOV_POS) + "\", got \"" + num2str(V_LevelX) + "\""
				return -1
			else
				For(j=1; j<Dimsize(tmat,1);j+=1) // Start at second column since first column is position
					temp[] = tmat[p][j] // Fill temp with the right column
					// The index below is corrected for the position column
					FIELDS[j-1][i] = temp(V_LevelX) // Igor will automatically interpolate a 1D wave.
				EndFor
			endif
			KillWaves temp
			
			MOVE_VOLTAGES[]	+= COMP_INFO[i][0] * FIELDS[p][i]
		EndFor
		CUR_POS=MOV_POS
		MOVE_VOLTAGES		*= COMP_INFO[6][0]
		RAW_VOLTAGES		= HOLD_VOLTAGES+LOAD_VOLTAGES+MOVE_VOLTAGES		
		sendVoltageGroup(RAW_VOLTAGES)
		MOVE_VOLTAGES=0
		RAW_VOLTAGES		= HOLD_VOLTAGES+LOAD_VOLTAGES
	else
		if(cur_pos>mov_pos)
			do
				For(i=0; i<6;i+=1)  // There are 6 different waveforms
					WAVE tmat = $("mat" + num2str(i))
					if(!WaveExists(tmat))
						FIELDS[][i] = 0
						continue
					endif
					// A temporary array to store the individual columns of tmat, minus the position column
					Make/O/N=(Dimsize(tmat,0)) temp
					FindLevel/Q tmat, CUR_POS
					if(V_LevelX >= Dimsize(tmat,0) || V_LevelX < 0)
						print "DC Update Error!"
						print "Could not find level \""+ num2str(CUR_POS) + "\", got \"" + num2str(V_LevelX) + "\""
						return -1
					else
						For(j=1; j<Dimsize(tmat,1);j+=1) // Start at second column since first column is position
							temp[] = tmat[p][j] // Fill temp with the right column
							// The index below is corrected for the position column
							FIELDS[j-1][i] = temp(V_LevelX) // Igor will automatically interpolate a 1D wave.
						EndFor
					endif
					KillWaves temp
					
					MOVE_VOLTAGES[]	+= COMP_INFO[i][0] * FIELDS[p][i]
				EndFor	
				MOVE_VOLTAGES		*= COMP_INFO[6][0]
				RAW_VOLTAGES		= HOLD_VOLTAGES+LOAD_VOLTAGES+MOVE_VOLTAGES			
				sendVoltageGroup(RAW_VOLTAGES)
				MOVE_VOLTAGES		=	0	
				cur_pos-=1
				//sleep/s 0.1
				RAW_VOLTAGES		= HOLD_VOLTAGES+LOAD_VOLTAGES
			while(CUR_POS!=MOV_POS)
		elseif(cur_pos<mov_pos)
			do
				For(i=0; i<6;i+=1)  // There are 6 different waveforms
					WAVE tmat = $("mat" + num2str(i))
					if(!WaveExists(tmat))
						FIELDS[][i] = 0
						continue
					endif
					// A temporary array to store the individual columns of tmat, minus the position column
					Make/O/N=(Dimsize(tmat,0)) temp
					FindLevel/Q tmat, CUR_POS
					if(V_LevelX >= Dimsize(tmat,0) || V_LevelX < 0)
						print "DC Update Error!"
						print "Could not find level \""+ num2str(CUR_POS) + "\", got \"" + num2str(V_LevelX) + "\""
						return -1
					else
						For(j=1; j<Dimsize(tmat,1);j+=1) // Start at second column since first column is position
							temp[] = tmat[p][j] // Fill temp with the right column
							// The index below is corrected for the position column
							FIELDS[j-1][i] = temp(V_LevelX) // Igor will automatically interpolate a 1D wave.
						EndFor
					endif
					KillWaves temp
					
				MOVE_VOLTAGES[]	+= COMP_INFO[i][0] * FIELDS[p][i]
				EndFor	
				MOVE_VOLTAGES		*= COMP_INFO[6][0]
				RAW_VOLTAGES		= HOLD_VOLTAGES+LOAD_VOLTAGES+MOVE_VOLTAGES				
				sendVoltageGroup(RAW_VOLTAGES)
				MOVE_VOLTAGES		=	0
				cur_pos+=1
				//sleep/s 0.1
				RAW_VOLTAGES		= HOLD_VOLTAGES+LOAD_VOLTAGES
			while(CUR_POS!=MOV_POS)
		endif
	endif	
End

function holdVoltages()

	SetDataFolder root:DCVolt
	
	WAVE COMP_INFO		=	root:ExpParams:COMP_INFO
	WAVE FIELDS
	WAVE RAW_VOLTAGES
	WAVE HOLD_VOLTAGES
	
	NVAR CUR_POS			=	root:ExpParams:CUR_POS
	NVAR HOLD_POS		=	root:ExpParams:HOLD_POS	
	NVAR HOLD_UP			=	root:ExpParams:HOLD_UP
	NVAR NUM_ELECT
	Variable i
	Variable j
	HOLD_VOLTAGES =0
	For(i=0; i<6;i+=1)  // There are 6 different waveforms
		WAVE tmat = $("mat" + num2str(i))
		if(!WaveExists(tmat))
			FIELDS[][i] = 0
			continue
		endif
		// A temporary array to store the individual columns of tmat, minus the position column
		Make/O/N=(Dimsize(tmat,0)) temp
		FindLevel/Q tmat, HOLD_POS
		if(V_LevelX >= Dimsize(tmat,0) || V_LevelX < 0)
			print "DC Update Error!"
			print "Could not find level \""+ num2str(HOLD_POS) + "\", got \"" + num2str(V_LevelX) + "\""
			return -1
		else
			For(j=1; j<Dimsize(tmat,1);j+=1) // Start at second column since first column is position
				temp[] = tmat[p][j] // Fill temp with the right column
				// The index below is corrected for the position column
				FIELDS[j-1][i] = temp(V_LevelX) // Igor will automatically interpolate a 1D wave.
			EndFor
		endif
		KillWaves temp
		
		HOLD_VOLTAGES	+= COMP_INFO[i][1] * FIELDS[p][i]
	EndFor
	HOLD_VOLTAGES		*= COMP_INFO[6][1]
end

function loadVoltages()

	SetDataFolder root:DCVolt
	
	WAVE COMP_INFO		=	root:ExpParams:COMP_INFO
	WAVE FIELDS
	WAVE RAW_VOLTAGES
	WAVE LOAD_VOLTAGES
	
	NVAR CUR_POS			=	root:ExpParams:CUR_POS
	NVAR LOAD_POS		=	root:ExpParams:LOAD_POS	
	NVAR HOLD_POS		=	root:ExpParams:HOLD_POS	
	NVAR HOLD_UP			=	root:ExpParams:HOLD_UP
	NVAR NUM_ELECT
	Variable i
	Variable j
	LOAD_VOLTAGES =0
	For(i=0; i<6;i+=1)  // There are 6 different waveforms
		WAVE tmat = $("mat" + num2str(i))
		if(!WaveExists(tmat))
			FIELDS[][i] = 0
			continue
		endif
		// A temporary array to store the individual columns of tmat, minus the position column
		Make/O/N=(Dimsize(tmat,0)) temp
		FindLevel/Q tmat,LOAD_POS
		if(V_LevelX >= Dimsize(tmat,0) || V_LevelX < 0)
			print "DC Update Error!"
			print "Could not find level \""+ num2str(LOAD_POS) + "\", got \"" + num2str(V_LevelX) + "\""
			return -1
		else
			For(j=1; j<Dimsize(tmat,1);j+=1) // Start at second column since first column is position
				temp[] = tmat[p][j] // Fill temp with the right column
				// The index below is corrected for the position column
				FIELDS[j-1][i] = temp(V_LevelX) // Igor will automatically interpolate a 1D wave.
			EndFor
		endif
		KillWaves temp
		
		LOAD_VOLTAGES	+= COMP_INFO[i][2] * FIELDS[p][i]
	EndFor
	LOAD_VOLTAGES		*= COMP_INFO[6][2]
end


function mergeToHOLDVoltages()
	SetDataFolder root:DCVolt
	
	WAVE COMP_INFO		=	root:ExpParams:COMP_INFO
	WAVE FIELDS
	WAVE RAW_VOLTAGES
	WAVE MOVE_VOLTAGES
	WAVE HOLD_VOLTAGES
	WAVE LOAD_VOLTAGES
	
	NVAR CUR_POS			=	root:ExpParams:CUR_POS
	NVAR MOV_POS		=	root:ExpParams:MOV_POS
	NVAR HOLD_POS		=	root:ExpParams:HOLD_POS
	NVAR LOAD_POS		=	root:ExpParams:LOAD_POS		
	NVAR HOLD_UP			=	root:ExpParams:HOLD_UP
	NVAR LOAD_UP			=	root:ExpParams:LOAD_UP			
	
	NVAR NUM_ELECT
	Variable i	
	Variable j
	if(HOLD_UP)
		holdVoltages()
	else
		HOLD_VOLTAGES=0
	endif
	if(LOAD_UP)
		loadVoltages()
	else
		LOAD_VOLTAGES=0
	endif
	RAW_VOLTAGES = LOAD_VOLTAGES+HOLD_VOLTAGES
	MOVE_VOLTAGES=0
	if(CUR_POS>HOLD_POS)
		do
//			For(i=0; i<6;i+=1)  // There are 6 different waveforms
				WAVE tmat = $("mat" + num2str(i))
				if(!WaveExists(tmat))
					FIELDS[][i] = 0
					continue
				endif
				// A temporary array to store the individual columns of tmat, minus the position column
				Make/O/N=(Dimsize(tmat,0)) temp
				FindLevel/Q tmat, CUR_POS
				if(V_LevelX >= Dimsize(tmat,0) || V_LevelX < 0)
					print "DC Update Error!"
					print "Could not find level \""+ num2str(CUR_POS) + "\", got \"" + num2str(V_LevelX) + "\""
					return -1
				else
					For(j=1; j<Dimsize(tmat,1);j+=1) // Start at second column since first column is position
						temp[] = tmat[p][j] // Fill temp with the right column
						// The index below is corrected for the position column
						FIELDS[j-1][6] = temp(V_LevelX) // Igor will automatically interpolate a 1D wave.
					EndFor
				endif
				KillWaves temp
				
				MOVE_VOLTAGES[]	+=  FIELDS[p][6]
//			EndFor	
//			RAW_VOLTAGES		*= COMP_INFO[6]
			sendVoltageGroup(MOVE_VOLTAGES)
			cur_pos-=1
			MOVE_VOLTAGES=0
		while(CUR_POS!=HOLD_POS)
	elseif(CUR_POS<HOLD_POS)
		do
//			For(i=0; i<6;i+=1)  // There are 6 different waveforms
				WAVE tmat = $("mat" + num2str(6))
				if(!WaveExists(tmat))
					FIELDS[][6] = 0
					continue
				endif
				// A temporary array to store the individual columns of tmat, minus the position column
				Make/O/N=(Dimsize(tmat,0)) temp
				FindLevel/Q tmat, CUR_POS
				if(V_LevelX >= Dimsize(tmat,0) || V_LevelX < 0)
					print "DC Update Error!"
					print "Could not find level \""+ num2str(CUR_POS) + "\", got \"" + num2str(V_LevelX) + "\""
					return -1
				else
					For(j=1; j<Dimsize(tmat,1);j+=1) // Start at second column since first column is position
						temp[] = tmat[p][j] // Fill temp with the right column
						// The index below is corrected for the position column
						FIELDS[j-1][6] = temp(V_LevelX) // Igor will automatically interpolate a 1D wave.
					EndFor
				endif
				KillWaves temp
				
				MOVE_VOLTAGES[]	+=  FIELDS[p][6]
//			EndFor	
//			RAW_VOLTAGES		*= COMP_INFO[6]
			sendVoltageGroup(MOVE_VOLTAGES)
			cur_pos+=1
			MOVE_VOLTAGES=0
		while(CUR_POS!=HOLD_POS)
	elseif(CUR_POS == HOLD_POS)
		sendVoltageGroup(RAW_VOLTAGES)
		RAW_VOLTAGES = 0	
	endif
End

function mergeToLoadVoltages()
	SetDataFolder root:DCVolt
	
	WAVE COMP_INFO		=	root:ExpParams:COMP_INFO
	WAVE FIELDS
	WAVE RAW_VOLTAGES
	WAVE MOVE_VOLTAGES
	WAVE HOLD_VOLTAGES
	WAVE LOAD_VOLTAGES
	
	NVAR CUR_POS			=	root:ExpParams:CUR_POS
	NVAR MOV_POS		=	root:ExpParams:MOV_POS
	NVAR HOLD_POS		=	root:ExpParams:HOLD_POS	
	NVAR LOAD_POS		=	root:ExpParams:LOAD_POS	
	NVAR HOLD_UP			=	root:ExpParams:HOLD_UP
	NVAR LOAD_UP			=	root:ExpParams:LOAD_UP			
	
	NVAR NUM_ELECT
	Variable i	
	Variable j
	if(HOLD_UP)
		holdVoltages()
	else
		HOLD_VOLTAGES=0
	endif
	if(LOAD_UP)
		loadVoltages()
	else
		LOAD_VOLTAGES=0
	endif
	RAW_VOLTAGES = LOAD_VOLTAGES+HOLD_VOLTAGES
	MOVE_VOLTAGES=0
	if(CUR_POS>LOAD_POS)
		do
//			For(i=0; i<6;i+=1)  // There are 6 different waveforms
				WAVE tmat = $("mat" + num2str(i))
				if(!WaveExists(tmat))
					FIELDS[][i] = 0
					continue
				endif
				// A temporary array to store the individual columns of tmat, minus the position column
				Make/O/N=(Dimsize(tmat,0)) temp
				FindLevel/Q tmat, CUR_POS
				if(V_LevelX >= Dimsize(tmat,0) || V_LevelX < 0)
					print "DC Update Error!"
					print "Could not find level \""+ num2str(CUR_POS) + "\", got \"" + num2str(V_LevelX) + "\""
					return -1
				else
					For(j=1; j<Dimsize(tmat,1);j+=1) // Start at second column since first column is position
						temp[] = tmat[p][j] // Fill temp with the right column
						// The index below is corrected for the position column
						FIELDS[j-1][6] = temp(V_LevelX) // Igor will automatically interpolate a 1D wave.
					EndFor
				endif
				KillWaves temp
				
				MOVE_VOLTAGES[]	+=  FIELDS[p][6]
//			EndFor	
//			RAW_VOLTAGES		*= COMP_INFO[6]
			sendVoltageGroup(MOVE_VOLTAGES)
			cur_pos-=1
			MOVE_VOLTAGES=0
		while(CUR_POS!=LOAD_POS)
	elseif(CUR_POS<LOAD_POS)
		do
//			For(i=0; i<6;i+=1)  // There are 6 different waveforms
				WAVE tmat = $("mat" + num2str(6))
				if(!WaveExists(tmat))
					FIELDS[][6] = 0
					continue
				endif
				// A temporary array to store the individual columns of tmat, minus the position column
				Make/O/N=(Dimsize(tmat,0)) temp
				FindLevel/Q tmat, CUR_POS
				if(V_LevelX >= Dimsize(tmat,0) || V_LevelX < 0)
					print "DC Update Error!"
					print "Could not find level \""+ num2str(CUR_POS) + "\", got \"" + num2str(V_LevelX) + "\""
					return -1
				else
					For(j=1; j<Dimsize(tmat,1);j+=1) // Start at second column since first column is position
						temp[] = tmat[p][j] // Fill temp with the right column
						// The index below is corrected for the position column
						FIELDS[j-1][6] = temp(V_LevelX) // Igor will automatically interpolate a 1D wave.
					EndFor
				endif
				KillWaves temp
				
				MOVE_VOLTAGES[]	+=  FIELDS[p][6]
//			EndFor	
//			RAW_VOLTAGES		*= COMP_INFO[6]
			sendVoltageGroup(MOVE_VOLTAGES)
			cur_pos+=1
			MOVE_VOLTAGES=0
		while(CUR_POS!=LOAD_POS)
	elseif(CUR_POS == LOAD_POS)
		sendVoltageGroup(RAW_VOLTAGES)
		RAW_VOLTAGES = 0	
	endif
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
	
	OUT_VOLTAGES = 0
	
	For(i=0;i<12;i+=1)
		CMDS[i]=""
	EndFor
	
	For(i=0;i<96;i+=1)
		FindValue/TEXT=num2str(i+1)/TXOP=4 HARDWARE_MAP
		if(V_Value < NUM_ELECT)
			OUT_VOLTAGES[i] = RAW_VOLTAGES[V_Value]
		endif
	EndFor
	
	overVoltWarning(OUT_VOLTAGES)
	
	For(i=0;i<96;i+=1)
		CMDS[floor(i/8)] += num2str(OUT_VOLTAGES[i]) + "," + num2str(i-8*floor(i/8)) + ";"
	EndFor
	
	For(i=0;i<12;i+=1)
		DAQmx_AO_SetOutputs /KEEP=1/DEV="D"+num2str(i+1) CMDS[i]
	EndFor
End

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

//Test Functions

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
















































