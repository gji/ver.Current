#pragma rtGlobals=1		// Use modern global access method.

//_____________________________________________________________________________
//_____________________________________________________________________________
//
//	This first Half of code is for the Pulse Creator panel which is used to create pulse 
//	sequences (without durations or frequency/amplitude/phase)
//_____________________________________________________________________________
//_____________________________________________________________________________
//

function ConstructSequencerInputs(expt)
	STRUCT Experiment &expt
	SetDataFolder root:Sequencer
	Make/O/N=0 SequenceDurations
	Variable ExOpIdx, durationIdx, seqIdx = 0
	for (ExOpIdx = 0; ExOpIdx < expt.numExOps; ExOpIdx +=1)
		durationIdx = WhichListItem("Duration", expt.ExOps[ExOpIdx].ControlParameters)
		if (durationIdx == -1 && cmpstr(expt.ExOps[ExOpIdx].name, "SBCooling") != 0)
			Abort "Experimental operation has no defined Duration control"
		endif
		strswitch(expt.ExOps[ExOpIdx].name)
			case "Cool":
			case "Pump":
			case "Detect":
			case "Rotation":
			case "MSGate":
				SequenceDurations[seqIdx] = str2num(StringFromList(durationIdx, expt.ExOps[ExOpIdx].Values))
				seqIdx += 1
				break
			case "SBCooling":
				
				break
			default:	
				Abort "Unknown ExOp type."
				break
		endswitch
	endfor
end

//_____________________________________________________________________________
//
// New Item button procedure - Adds new item to pulse sequence
//_____________________________________________________________________________
//
Function NewItemPressed(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SetDataFolder root:ExpParams
	wave GroupVals
	
	switch( ba.eventCode )
		case 2: // mouse up
			Variable numItem = str2num(GetUserData("PulseCreator", "NewItem", ""))
			numItem += 1
			InsertPoints numItem-1,1,GroupVals
			if(numItem > 1)
				GroupVals[numItem-1] = GroupVals[numItem-2]
			else
				GroupVals[numItem-1] = 1
			endif
			InsertPoints numItem-1,1,PopupVals
			Button NewItem userdata=num2str(numItem)
			
			PopupMenu $("StepType"+num2str(numItem)) win=PulseCreator, pos={15,numItem*30+16}, value=MakeNames(), Title="Step " + num2str(numItem), proc=StepTypeChanged
			if(numItem > 1)
				CheckBox $("NewGroup"+num2str(numItem))win=PulseCreator, pos={200,numItem*30+16+4}, title= "New Group", size={80,20}, proc=NewGroupChecked
			endif
			ValDisplay $("GroupVal"+num2str(numItem)) win=PulseCreator, pos={285,numItem*30+16+4}, frame=2, size={20,20}, value=#("root:ExpParams:GroupVals["+num2str(numItem-1)+"]")

			KillControl/W=PulseCreator ExportSeq
			GetWindow PulseCreator wsize
			MoveWindow/W=PulseCreator V_left,V_top,V_left+250,(68+V_top+numItem*30+16)*72/ScreenResolution
			ClearLoops()
		case -1: // control being killed
	endswitch
	return 0
End

//_____________________________________________________________________________
//
// 
//_____________________________________________________________________________
//
Function/S MakeNames()
	SetDataFolder root:ExpParams
	WAVE/T TTLNames
	String nametoreturn=""
	
	Variable i
	for(i=0;i<dimsize(TTLNames,0);i+=1)
		nametoreturn += SelectString(i==0,";","") + TTLNames[i] 
	endfor
	
	Return nametoreturn
End

//_____________________________________________________________________________
//
// Delete Item button procedure - removes previous item from pulse sequence 
//_____________________________________________________________________________
//
Function DeleteItemPressed(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	SetDataFolder root:ExpParams
	wave GroupVals
	
	switch( ba.eventCode )
		case 2: // mouse up
			Variable numItem = str2num(GetUserData("PulseCreator", "NewItem", ""))
			
			If (numItem>0)
				KillControl/W=PulseCreator $("StepType"+num2str(numItem))
				KillControl/W=PulseCreator $("NewGroup"+num2str(numItem))
				KillControl/W=PulseCreator $("GroupVal"+num2str(numItem))
				KillControl/W=PulseCreator ExportSeq
				ClearLoops()
				
				numItem -= 1
				DeletePoints numItem,1,GroupVals
				DeletePoints numItem,1,PopupVals
				Button NewItem userdata=num2str(numItem)
				
				GetWindow PulseCreator wsize
				MoveWindow/W=PulseCreator V_left,V_top,V_left+250,(68+V_top+numItem*30+16)*72/ScreenResolution
			Endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//_____________________________________________________________________________
//
// Executed when the step is changed
//_____________________________________________________________________________
//
Function StepTypeChanged(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	SetDataFolder root:ExpParams
	wave PopupVals

	String popupNumSt
	SplitString/E=("StepType([0-9]+)") ctrlname, popupNumSt
	Variable popupNum = str2num(popupNumSt)
	
	PopupVals[popupNum-1]=popNum-1
End

//_____________________________________________________________________________
//
// Executed when new group checkbox clicked
//_____________________________________________________________________________
//
Function NewGroupChecked(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	KillControl/W=PulseCreator ExportSeq
	ClearLoops()
	Variable numItem = str2num(GetUserData("PulseCreator", "NewItem", ""))
	GetWindow PulseCreator wsize
	MoveWindow/W=PulseCreator V_left,V_top,V_left+250,(68+V_top+numItem*30+16)*72/ScreenResolution
	
	SetDataFolder root:ExpParams
	wave GroupVals
	
	String groupNumSt
	SplitString/E=("NewGroup([0-9]+)") ctrlname, groupNumSt
	Variable groupNum = str2num(groupNumSt)

	Variable i
	for(i=groupNum-1; i<DimSize(GroupVals,0); i+=1)
		GroupVals[i] += (checked==0?-1:1)
	endfor
End

//_____________________________________________________________________________
//
//Set Loops button procedure - generates loop inputs and export sequence button
//_____________________________________________________________________________
//
Function SetLoopsPressed(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SetDataFolder root:ExpParams
	NVAR GroupError
	
	switch( ba.eventCode )
		case 2: // mouse up
			Variable numItem = str2num(GetUserData("PulseCreator", "NewItem", ""))

			if (numItem>0)
				GenerateLoops()
				
				GetWindow PulseCreator wsize
				MoveWindow/W=PulseCreator V_left,V_top,V_left+350,(68+V_top+numItem*30+16)*72/ScreenResolution
			Endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//_____________________________________________________________________________
//
//Generates the loop input controls
//_____________________________________________________________________________
//
Function GenerateLoops()
	SetDataFolder root:ExpParams

	WAVE GroupVals
	Variable i=0
	
	Variable groupNumber = GroupVals[str2num(GetUserData("PulseCreator", "NewItem", ""))]
	Make/O/N=(groupNumber) LoopVals=1
	
	Variable VerticalLoopPosition=16	
	ClearLoops()
	
	For (i=0;i<groupNumber;i+=1)
		VerticalLoopPosition+=30
		SetVariable $("LoopGroup"+num2str(i+1)) win=PulseCreator,pos={321,VerticalLoopPosition+2},title="Group "+num2str(i+1)+" Loops", size={120,20}, value=LoopVals[i], limits={1,1024,1}
	EndFor
	Button ExportSeq win=PulseCreator, proc=ExportSequencePressed, pos={321,16},title="Export Sequence", size={100,20}, userdata=num2str(groupNumber)
End

//_____________________________________________________________________________
//
// Deletes all loop controls
//_____________________________________________________________________________
//
Function ClearLoops()
	SetDataFolder root:ExpParams
	
	String controlNames = ControlNameList("PulseCreator")
	Variable i
	do
		String ctrlName = StringFromList(i,controlNames)
		if(strlen(ctrlName) == 0)
			break
		endif
		if(GrepString(ctrlName,"LoopGroup[0-9]+"))
			KillControl/W=PulseCreator $ctrlName
		endif
		i+=1
	while(1)
End

//_____________________________________________________________________________
//
// Export Sequence button procedure - exports sequence
//_____________________________________________________________________________
//
Function ExportSequencePressed(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SetDataFolder root:ExpParams
	NVAR TooLong	
	WAVE PulseCreatorWave = root:ExpParams:PulseCreatorWave
	switch( ba.eventCode )
		case 2: // mouse up
			If (TestWaveSize()==0)
				CreateWave()
				PauseUpdate; Silent 1		// building window...
				NewPanel/N=SaveSequenceWindow/K=0/W=(806,108,1138,208) as "Save Sequence Type as..."
				SetVariable SequenceNamefield pos={100,17.5},size={195,20},BodyWidth=185,title="Sequence Type Name:",value=_STR:"SequenceName"
				Button WaveSaveButton pos={197.5,57.5},size={100,20},title="Save Sequence",proc=ExportSequenceProc	
				//Save/P=SequencesPath/G/I/W PulseCreatorWave
			Endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//_____________________________________________________________________________
//
//	Procedures for Save Settings Button - Saves current scan bounds and checkboxes
//_____________________________________________________________________________
//
Function ExportSequenceProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	WAVE PulseCreatorWave = root:ExpParams:PulseCreatorWave
	switch(ba.eventCode)
		case 2: //mouse up
			NewDataFolder/O/S root:Sequences
			ControlInfo/W=SaveSequenceWindow SequenceNamefield
			String SequenceName=S_Value	
			//NewDataFolder/O/S $("root:Settings:"+SequenceName)
			Make/O/N=(DimSize(PulseCreatorWave,0),DimSize(PulseCreatorWave,1)) $(SequenceName)
			Wave tempWave = $(SequenceName)
			tempWave = PulseCreatorWave
			DoWindow/K SaveSequenceWindow
			break
		case -1:
			
			break
	endswitch
End

//_____________________________________________________________________________
//
// Export Sequence button procedure - exports sequence
//_____________________________________________________________________________
//
//Function ExportSequencePressedOLD(ba) : ButtonControl
//	STRUCT WMButtonAction &ba
//	SetDataFolder root:ExpParams
//	NVAR TooLong	
//	WAVE PulseCreatorWave
//	switch( ba.eventCode )
//		case 2: // mouse up
//			DoWindow/K SaveWaveWindow
//		
//			If (TestWaveSize()==0)
//				CreateWave()
//				Save/P=SequencesPath/G/I/W PulseCreatorWave
//			Endif
//			break
//		case -1: // control being killed
//			break
//	endswitch
//
//	return 0
//End

//_____________________________________________________________________________
//
// Checks to make sure that the exported sequence is not longer than the size allowed by the FPGA
// Returns 0 if OK
//_____________________________________________________________________________
//
Function TestWaveSize()
	SetDatafolder root:ExpParams
	WAVE PopupVals
	WAVE GroupVals
	WAVE LoopVals
	
	Variable numItem = str2num(GetUserData("PulseCreator", "NewItem", ""))
	
	Variable TooLong
	Variable TotalSize=0
	Variable GroupSize=1
	Variable CurrentGroup=1
	Variable i
	
	TooLong=0
	For (i=0;i<numItem;i+=1)
		if (GroupVals[i+1]==GroupVals[i])
			GroupSize+=1
		Else
			TotalSize+=GroupSize*LoopVals[CurrentGroup-1]
			CurrentGroup+=1
			GroupSize=1
		Endif
	EndFor
	TotalSize+=GroupSize*LoopVals[CurrentGroup-1]
	If (TotalSize>1024)
		DoAlert/T="Sequence Length Problem" 0, "Sequence Is Too Long"
		TooLong=1
	Endif
	
	return TooLong
End

//_____________________________________________________________________________
//
//Takes info from the step name, group numbers, and loop numbers and creates a wave
//_____________________________________________________________________________
//
Function CreateWave()
	SetDataFolder root:ExpParams
	WAVE PopupVals
	WAVE GroupVals
	WAVE LoopVals
	WAVE PulseCreatorWave
	
	PulseCreatorWave[][0]=(p<DimSize(PopupVals,0)?PopupVals[p]:0)
	PulseCreatorWave[][1]=(p<DimSize(GroupVals,0)?GroupVals[p]:0)
	PulseCreatorWave[][2]=(p<DimSize(LoopVals,0)?LoopVals[p]:0)
End


//_____________________________________________________________________________
//_____________________________________________________________________________
//
//	This second half of code is for the Pulse program panel which is used to set parameters for 
//	a pulse sequence and send them to the fpga to be run
//_____________________________________________________________________________
//_____________________________________________________________________________
//



//_____________________________________________________________________________
//
//  Sequence Popup Menu Control - Generates titles, scan options, cycles and run controls
//_____________________________________________________________________________
//
Function PopMenuProcOLD(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	SetDataFolder root:ExpParams
	Make/O/N=(1024,3) LoadedWave 
	WAVE wave0
	WAVE/T LoadWaveFiles
	Variable i,position
	Variable count=0
	
	switch(pa.eventcode)
		Case 2:
			For(i=0;i<dimsize(LoadWaveFiles,0);i+=1)
				If(i==pa.popNum-2)
					ClearScanControls()
					Wave0=0
					LoadedWave=0
					LoadWave/D/H/J/M/P=SequencesPath/N/G LoadWaveFiles[i]	// Loads data into WAVE "wave0" by default
					LoadedWave=Wave0
					
					GenerateScanControlsOLD(LoadedWave,DefaultSettings())
					CreateButtons()
					ControlInfo SetScan
					position=V_top
					GetWindow Pulse wsize
					MoveWindow/W=Pulse V_left,V_top,V_left+950,(100+V_top+position)*72/ScreenResolution
					count=1
					break
				Endif				
			endFor
			If (count==0)
				ClearScanControls()
				GetWindow Pulse wsize
				MoveWindow/W=Pulse V_left,V_top,V_left+250,(130+V_top)*72/ScreenResolution
			Endif
			break
		case -1:
			break
	Endswitch
	
	return 0
End

//_____________________________________________________________________________
//
//  Load Settings Popup Menu Control - 
//_____________________________________________________________________________
//
Function LoadSettingsPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	WAVE LoadedWave = root:ExpParams:LoadedWave
	
	switch(pa.eventcode)
		Case 2:
			String SettingName = pa.popStr
			ControlInfo/W=Pulse Sequence
			String SequenceName=S_Value	
			String PathToSettingWave = "root:Settings:"+SequenceName+":"+SettingName

			// This is where the code to implement a settings loading scheme would go
			Wave tempWave = $("root:Sequences:"+SequenceName)
			LoadedWave = tempWave
				
			STRUCT Experiment expt
			GetExperiment(expt)
			ImportExptFromJSONString(expt, PathToSettingWave)
			// Print the current Experiment structure state
			Variable ExOpIdx
			//for (ExOpIdx = 0; ExOpIdx < expt.numExOps; ExOpIdx +=1)
			//	Print expt.ExOps[ExOpIdx]
			//endfor
			RecreateSequenceControls(expt)
			CreateButtons()
			ControlInfo LoadSettings
			Variable position=V_top
			GetWindow Pulse wsize
			MoveWindow/W=Pulse V_left,V_top,V_left+650,(125+V_top+position)*72/ScreenResolution
//			Wave/T tempWave = $(PathToSettingWave)
//			ClearScanControls()
//			GetWindow Pulse wsize
//			MoveWindow/W=Pulse V_left,V_top,V_left+250,(150+V_top)*72/ScreenResolution
//			Variable k
//			for (k=0; k < numpnts(tempWave); k+=1)
//				Execute tempWave[k]
//			endfor
			break
		case -1:
			break
	Endswitch
end

//_____________________________________________________________________________
//
//  Sequence Popup Menu Control - Generates titles, scan options, cycles and run controls
//_____________________________________________________________________________
//
Function PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	SetDataFolder root:ExpParams
	Make/O/N=(1024,3) LoadedWave 
	WAVE wave0
	WAVE/T LoadWaveFiles
	Variable i,position
	Variable loadedFlag=0
	
	switch(pa.eventcode)
		Case 2:
			String SequenceName = pa.popStr
			if (cmpstr(SequenceName, " ") == 0)
				ClearScanControls()
				GetWindow Pulse wsize
				MoveWindow/W=Pulse V_left,V_top,V_left+250,(150+V_top)*72/ScreenResolution
			else
				Wave tempWave = $("root:Sequences:"+SequenceName)
				LoadedWave = tempWave					
		
				WAVE/T ExOpNames = TTLNames
				STRUCT Experiment expt
				Variable/G TotalStep	
				TotalStep=FindtotalStep()	
				Make/O/T/N=(TotalStep) ExpSeq = ""
				Variable k
				for (k=0;k<TotalStep;k+=1)
					ExpSeq[k] = ExOpNames[LoadedWave[k]]
				endfor	
			
				BuildExperiment(ExpSeq, expt)
				
				GenerateSequenceControls(expt)
				CreateButtons()
				ControlInfo LoadSettings
				position=V_top
				GetWindow Pulse wsize
				MoveWindow/W=Pulse V_left,V_top,V_left+650,(125+V_top+position)*72/ScreenResolution
			endif
			break
		case -1:
			break
	Endswitch
	
	return 0
End

//_____________________________________________________________________________
//
//	Builds sequence of experimental operations (ExOps) and generate scan controls
//_____________________________________________________________________________
//
Function GenerateSequenceControls(expt)
	STRUCT Experiment &expt
	Variable k
	SetDataFolder root:ExpParams	
	
	ClearScanControls()
	
	NVAR VerticalButtonPosition
	NVAR MIN_POSITION
	NVAR MAX_POSITION
	NVAR DEFAULT_POSITION
	
	VerticalButtonPosition=65
	Variable ExOpIdx
	Variable numControlParams
	String ControlParamName
	String ExOpName
	Variable minVal, maxVal, minInc, DefaultVal
	String userdataStr

	for (ExOpIdx = 0; ExOpIdx < expt.numExOps; ExOpIdx +=1)
		ExOpName =  expt.ExOps[ExOpIdx].name

		TitleBox $("Step"+num2str(ExOpIdx)+"Title"),labelBack=(65535,65535,65535),frame=5, fixedSize=1,anchor=MC,pos={15,VerticalButtonPosition},size={150,20}, title=ExOpName,win=Pulse
		SetVariable $("Step"+num2str(ExOpIdx)+"position"), pos={240, VerticalButtonPosition+2}, title="Position", win=Pulse,size={100,20},bodywidth=30,limits={MIN_POSITION,MAX_POSITION,1},value=_NUM:DEFAULT_POSITION
		if (cmpstr(ExOpName, "SBCooling") == 0)
			SetVariable $("Step"+num2str(ExOpIdx)+"SBCNumModes"), pos={140, VerticalButtonPosition+2}, title="Modes", win=Pulse,size={100,20},bodywidth=30,limits={1,20,1},value=_NUM:1, proc=GenerateSBCoolingControls
			VerticalButtonPosition+=100
		else
			numControlParams = GetNumberControlParams(expt.ExOps[ExOpIdx])

			for (k=0; k < numControlParams; k+=1)
				ControlParamName = ExOpElement(expt.ExOps[ExOpIdx].ControlParameters, k)
				
				minVal = str2num(ExOpElement(expt.ExOps[ExOpIdx].MinVal, k))
				maxVal = str2num(ExOpElement(expt.ExOps[ExOpIdx].MaxVal, k))
				minInc = str2num(ExOpElement(expt.ExOps[ExOpIdx].MinInc, k))
				
				userdataStr = ExOpName+";"+ ControlParamName+";"
				CheckBox $("Step"+num2str(ExOpIdx)+"Scan"+num2str(k)), pos={170,VerticalButtonPosition+2}, title=ControlParamName, win=Pulse, proc=ConstructScanControls, value=0, userdata=userdataStr
				if ( str2num(ExOpElement(expt.ExOps[ExOpIdx].ScannableParameters, k)) == 0 )
					CheckBox $("Step"+num2str(ExOpIdx)+"Scan"+num2str(k)), disable=2
				endif
				DefaultVal = str2num(ExOpElement(expt.ExOps[ExOpIdx].Values, k))
				SetVariable $("Step"+num2str(ExOpIdx)+"setpoint"+num2str(k)), pos={340, VerticalButtonPosition+2}, title=ControlParamName, win=Pulse,size={130,20},bodywidth=50,limits={minVal,maxVal,minInc},value=_NUM:DefaultVal
				VerticalButtonPosition+=25
			endfor
		endif
	endfor
End


//_____________________________________________________________________________
//
//	Recreates sequence of experimental operations (ExOps) and generate scan controls
//_____________________________________________________________________________
//
Function RecreateSequenceControls(expt)
	STRUCT Experiment &expt
	SetDataFolder root:ExpParams	
	Variable k

	ClearScanControls()
	
	NVAR VerticalButtonPosition
	NVAR MIN_POSITION
	NVAR MAX_POSITION
	NVAR DEFAULT_POSITION
	
	VerticalButtonPosition=65
	Variable ExOpIdx
	Variable numControlParams
	String ControlParamName
	String ExOpName
	Variable minVal, maxVal, minInc, DefaultVal
	String userdataStr

	for (ExOpIdx = 0; ExOpIdx < expt.numExOps; ExOpIdx +=1)
		ExOpName =  expt.ExOps[ExOpIdx].name

		TitleBox $("Step"+num2str(ExOpIdx)+"Title"),labelBack=(65535,65535,65535),frame=5, fixedSize=1,anchor=MC,pos={15,VerticalButtonPosition},size={150,20}, title=ExOpName,win=Pulse
		SetVariable $("Step"+num2str(ExOpIdx)+"position"), pos={240, VerticalButtonPosition+2}, title="Position", win=Pulse,size={100,20},bodywidth=30,limits={MIN_POSITION,MAX_POSITION,1},value=_NUM:DEFAULT_POSITION
		if (cmpstr(ExOpName, "SBCooling") == 0)
			SetVariable $("Step"+num2str(ExOpIdx)+"SBCNumModes"), pos={140, VerticalButtonPosition+2}, title="Modes", win=Pulse,size={100,20},bodywidth=30,limits={1,20,1},value=_NUM:1, proc=GenerateSBCoolingControls
			VerticalButtonPosition+=100
		else
			numControlParams = GetNumberControlParams(expt.ExOps[ExOpIdx])

			for (k=0; k < numControlParams; k+=1)
				ControlParamName = ExOpElement(expt.ExOps[ExOpIdx].ControlParameters, k)
				
				minVal = str2num(ExOpElement(expt.ExOps[ExOpIdx].MinVal, k))
				maxVal = str2num(ExOpElement(expt.ExOps[ExOpIdx].MaxVal, k))
				minInc = str2num(ExOpElement(expt.ExOps[ExOpIdx].MinInc, k))
				
				userdataStr = ExOpName+";"+ ControlParamName+";"
				CheckBox $("Step"+num2str(ExOpIdx)+"Scan"+num2str(k)), pos={170,VerticalButtonPosition+2}, title=ControlParamName, win=Pulse, proc=ConstructScanControls, value=0, userdata=userdataStr
				if ( expt.ExOps[ExOpIdx].Scanned == 1 && cmpstr(ControlParamName, ExOpElement(expt.ExOps[ExOpIdx].ControlParameters, expt.ExOps[ExOpIdx].ScanParameter)) == 0 )
					print ExOpName

					CheckBox $("Step"+num2str(ExOpIdx)+"Scan"+num2str(k)), value=1
					Variable elementIdx = WhichListItem(ControlParamName, expt.ExOps[ExOpIdx].ControlParameters)
					//minVal = str2num(ExOpElement(expt.ExOps[ExOpIdx].MinVal, elementIdx))
					//maxVal = str2num(ExOpElement(expt.ExOps[ExOpIdx].MaxVal, elementIdx))
					//minInc = str2num(ExOpElement(expt.ExOps[ExOpIdx].MinInc, elementIdx))
					Variable scanStart = expt.ExOps[ExOpIdx].scanStart
					Variable scanStop = expt.ExOps[ExOpIdx].scanStop
					Variable scanInc = expt.ExOps[ExOpIdx].scanInc
					SetVariable $("Step"+num2str(ExOpIdx)+"Scan"+num2str(k)+"Min"), pos={170+300, VerticalButtonPosition}, title="Min", win=Pulse,size={130,20},bodywidth=50,limits={minVal,maxVal,minInc},value=_NUM:scanStart
					SetVariable $("Step"+num2str(ExOpIdx)+"Scan"+num2str(k)+"Max"), pos={170+400, VerticalButtonPosition}, title="Max", win=Pulse,size={130,20},bodywidth=50,limits={minVal,maxVal,minInc},value=_NUM:scanStop
					SetVariable $("Step"+num2str(ExOpIdx)+"Scan"+num2str(k)+"Inc"), pos={170+500, VerticalButtonPosition}, title="Inc", win=Pulse,size={130,20},bodywidth=50,limits={minInc,maxVal,minInc},value=_NUM:scanInc

				endif
				if ( str2num(ExOpElement(expt.ExOps[ExOpIdx].ScannableParameters, k)) == 0 )
					CheckBox $("Step"+num2str(ExOpIdx)+"Scan"+num2str(k)), disable=2
				endif
				DefaultVal = str2num(ExOpElement(expt.ExOps[ExOpIdx].Values, k))
				SetVariable $("Step"+num2str(ExOpIdx)+"setpoint"+num2str(k)), pos={340, VerticalButtonPosition+2}, title=ControlParamName, win=Pulse,size={130,20},bodywidth=50,limits={minVal,maxVal,minInc},value=_NUM:DefaultVal
				VerticalButtonPosition+=25
			endfor
		endif
	endfor
End

Function GenerateSBCoolingControls(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	ControlInfo/W=Pulse $(sva.ctrlName)	
	Variable VerticalButtonPosition = V_top
	
	String numStep
	SplitString/E="Step([0-9]+)SBCNumModes" sva.ctrlName, numStep
	
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			Variable dval = sva.dval
			String sval = sva.sval
			String controlNames = ControlNameList("Pulse")
			Variable i
			do
				String ctrlName = StringFromList(i,controlNames)
				if(strlen(ctrlName) == 0)
					break
				endif
				if(GrepString(ctrlName,"Step[0-9]+SBCooling(Freq|Time|Amplitude|Cycles)[0-9]+"))
					KillControl/W=Pulse $ctrlName
				endif
				i+=1
			while(1)
			
			Variable k
			for (k=0; k < dval; k+=1)
				SetVariable $("Step"+(numStep)+"SBCoolingFreq"+num2str(k)), pos={370+50*k, VerticalButtonPosition+2}, win=Pulse,size={100,20},bodywidth=50,limits={10,300,0.0005},value=_NUM:250
				SetVariable $("Step"+(numStep)+"SBCoolingTime"+num2str(k)), pos={370+50*k, VerticalButtonPosition+25}, win=Pulse,size={100,20},bodywidth=50,limits={1,500,1},value=_NUM:20
				SetVariable $("Step"+(numStep)+"SBCoolingAmplitude"+num2str(k)), pos={370+50*k, VerticalButtonPosition+50}, win=Pulse,size={100,20},bodywidth=50,limits={1,500,1},value=_NUM:2047
				SetVariable $("Step"+(numStep)+"SBCoolingCycles"+num2str(k)), pos={370+50*k, VerticalButtonPosition+75}, win=Pulse,size={100,20},bodywidth=50,limits={1,500,1},value=_NUM:10
			endfor
		case 3: // Live update
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//_____________________________________________________________________________
//
//	ConstructScanControls(cba) : CheckBoxControl 
//	When the scan toggle checkbox is checked, create the scan controls for that control
//	parameter. When it is unchecked, delete those controls.
//_____________________________________________________________________________
//
Function ConstructScanControls(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	SetDataFolder root:ExpParams	
	WAVE sequence = LoadedWave
	WAVE/T ExOpNames = TTLNames
	STRUCT Experiment expt
	Variable/G TotalStep	
	TotalStep=FindtotalStep()	
	Make/O/T/N=(TotalStep) ExpSeq = ""
	Variable k
	for (k=0;k<TotalStep;k+=1)
		ExpSeq[k] = ExOpNames[sequence[k]]
	endfor	
	BuildExperiment(ExpSeq, expt)
	
	String ControlParamName
	String ExOpName
	Variable minVal, maxVal, minInc, ExOpIdx, elementIdx
	
	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if (checked)
				ControlInfo/W=Pulse $(cba.ctrlName)
				ExOpName = StringFromList(0,S_userdata,";")
				ControlParamName = StringFromList(1,S_userdata,";")
				for (ExOpIdx = 0; ExOpIdx < expt.numExOps; ExOpIdx +=1)
					if (cmpstr(expt.ExOps[ExOpIdx].name, ExOpName) == 0)
						elementIdx = WhichListItem(ControlParamName, expt.ExOps[ExOpIdx].ControlParameters)
						minVal = str2num(ExOpElement(expt.ExOps[ExOpIdx].MinVal, elementIdx))
						maxVal = str2num(ExOpElement(expt.ExOps[ExOpIdx].MaxVal, elementIdx))
						minInc = str2num(ExOpElement(expt.ExOps[ExOpIdx].MinInc, elementIdx))
						break
					endif
				endfor
				SetVariable $(cba.ctrlName+"Min"), pos={V_left+300, V_top}, title="Min", win=Pulse,size={130,20},bodywidth=50,limits={minVal,maxVal,minInc},value=_NUM:minVal 
				SetVariable $(cba.ctrlName+"Max"), pos={V_left+400, V_top}, title="Max", win=Pulse,size={130,20},bodywidth=50,limits={minVal,maxVal,minInc},value=_NUM:maxVal
				SetVariable $(cba.ctrlName+"Inc"), pos={V_left+500, V_top}, title="Inc", win=Pulse,size={130,20},bodywidth=50,limits={minInc,maxVal,minInc},value=_NUM:minInc 
			else
				KillControl/W=Pulse $(cba.ctrlName+"Min")
				KillControl/W=Pulse $(cba.ctrlName+"Max")
				KillControl/W=Pulse $(cba.ctrlName+"Inc")
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//_____________________________________________________________________________
//
//	GetNumberControlParams(op) returns the number of control parameters in an ExOp
//_____________________________________________________________________________
//
function GetNumberControlParams(op)
	STRUCT ExOp &op
	Variable k = 0
	Variable numControlParams = 0
	do
		if (strlen(ExOpElement(op.ControlParameters, k))== 0)
			break
		else
			numControlParams += 1
		endif
		k += 1	
	while (1)
	return numControlParams
end

//_____________________________________________________________________________
//
//	GetNumberScannableParams(op) returns the number of scannable parameters in an ExOp
//_____________________________________________________________________________
//
function GetNumberScannableParams(op)
	STRUCT ExOp &op
	Variable k = 0
	Variable numScannableParams = 0
	String strVal
	do
		strVal = ExOpElement(op.ControlParameters, k)
		if (strlen(strVal)== 0)
			break
		else
			if (str2num(strVal) == 1)
				numScannableParams += 1
			endif
		endif
		k += 1	
	while (1)
	return numScannableParams
end

//_____________________________________________________________________________
//
//	Cycles through passed wave and generates title and scan controls for each item
//_____________________________________________________________________________
//
Function GenerateScanControlsOLD(load,settingwave)
	WAVE load
	Wave settingwave
	SetDataFolder root:ExpParams
	NVAR DELAY
	NVAR COOL
	NVAR STATE_DET
	NVAR FLR_DET
	NVAR PUMP
	NVAR COOL_SHTR
	NVAR RAMAN1
	NVAR RAMAN2
	NVAR PMT
	NVAR VerticalButtonPosition

	ClearScanControls()
	
	Variable i,j
	Variable/G TotalStep	
	TotalStep=FindtotalStep()
	VerticalButtonPosition=65
	
	TitleBox Group1Title,frame=4,fixedSize=1,labelBack=(0,0,0),fColor=(65535,65535,65535),anchor=MC,pos={75,VerticalButtonPosition-25},size={150,20}, title="Group: "+num2str(load[0][1])+" Loops: "+num2str(load[load[0][1]-1][2])
	
	String existingPulses = ""
	For (j=0; j<TotalStep; j+=1)
		If (j>0)
			If (load[j][1]!=load[j-1][1])
				TitleBox $("Group"+num2str(load[j][1])+"Title"), fixedSize=1,frame=4,labelBack=(0,0,0),fColor=(65535,65535,65535),anchor=MC,pos={75,VerticalButtonPosition},size={150,20}, title="Group: "+num2str(load[j][1])+" Loops: "+num2str(load[load[j][1]-1][2])
				VerticalButtonPosition+=25
			Endif
		Endif
		existingPulses = GenerateScan(load[j][0],j,settingwave,existingPulses)
	EndFor
	
End

//_____________________________________________________________________________
//
// Generates title and scan controls for a passed operation name
// We do this by looking up the operation in a string that contains
// all the controls each operation needs, then looping through the 
// controls and displaying the proper one. The +2 on the checkbox
// simply centers it w.r.t. other controls.
// Eventually the lookup table should be in init
// The various parameters are:
// TTL 1,7,8: AOM
// TTL 10: EOM
// TTL 2,3: AOM + EOM
// This function intelligently links scans of the same frequency source
// and returns an updated list of frequency sources that are being scanned
//_____________________________________________________________________________
//
Function/S GenerateScan(name,step,settingwave,existingPulses)
	WAVE settingwave
	Variable name,step
	String existingPulses
	
	SetDataFolder root:ExpParams
	WAVE/T TTLNames
	NVAR VerticalButtonPosition
	SVAR TTL_PARAMS
	SVAR SCAN_TITLES
	
	TitleBox $("Step"+num2str(step+1)+"Title"),labelBack=(65535,65535,65535),frame=5, fixedSize=1,anchor=MC,pos={15,VerticalButtonPosition},size={150,20}, title=TTLNames[name],win=Pulse

	String commandsToExecute = StringFromList(name, TTL_PARAMS) // Grab the right commands
	if(stringmatch(commandsToExecute,""))
		commandsToExecute = "0"
	endif
	
	Variable beenScanned = 0
	if(stringmatch(ListMatch(existingPulses, num2str(name)+",*"), "")) // if it's already been scanned, mark it as so
		existingPulses += num2str(name) + "," + num2str(step) + ";"
	else
		beenScanned = str2num(StringFromList(1,ListMatch(existingPulses, num2str(name)+",*"),",")) + 1 // grabs step, +1 to avoid step=0 meaning no scan
	endif
	
	Variable i=0
	String valStr;
	for(i=0; i<strlen(commandsToExecute); i+=1)
		Variable index = str2num(commandsToExecute[i])

		CheckBox $("Step"+num2str(step+1)+"Scan"+num2str(index)), pos={170,VerticalButtonPosition+2}, title=StringFromList(index, SCAN_TITLES), win=Pulse,value=settingwave[7*step+index+1][0]
		
		if(index > 0)
			if(beenScanned == 0)
				Variable/G $("Step"+num2str(step+1)+"Scan"+num2str(index)+"Value")
				CheckBox $("Step"+num2str(step+1)+"Scan"+num2str(index)), variable=$("Step"+num2str(step+1)+"Scan"+num2str(index)+"Value")
			else
				CheckBox $("Step"+num2str(step+1)+"Scan"+num2str(index)), variable=$("Step"+num2str(beenScanned)+"Scan"+num2str(index)+"Value")
			endif
		endif

		VerticalButtonPosition += 20
	endfor
	
	return existingPulses
End

//_____________________________________________________________________________
//
// Deletes all current scan controls, titles, buttons, and loops
// i.e. everything but the sequence selector
//_____________________________________________________________________________
//
Function ClearScanControls()
	String controlNames = ControlNameList("Pulse")
	Variable i
	do
		String ctrlName = StringFromList(i,controlNames)
		if(strlen(ctrlName) == 0)
			break
		endif
		if(!stringmatch(ctrlName,"Sequence"))
			KillControl/W=Pulse $ctrlName
		endif
		i+=1
	while(1)
End

//_____________________________________________________________________________
//
// Resets to before scan bounds were generated
//_____________________________________________________________________________
//
Function ClearScanBounds()
	String controlNames = ControlNameList("Pulse")
	Variable i
	do
		String ctrlName = StringFromList(i,controlNames)
		if(strlen(ctrlName) == 0)
			break
		endif
		if(GrepString(ctrlName,"Step[0-9]+(lower|upper|inc|Inc|setpoint|ScanOrder).*"))
			KillControl/W=Pulse $ctrlName
		endif
		i+=1
	while(1)
End

//_____________________________________________________________________________
//
//	GenerateBounds(load, settingwave) creates the ExOp parameter and scan controls
//_____________________________________________________________________________
//
Function GenerateBounds(load, settingwave)
	wave load
	wave Settingwave
	
	SetDataFolder root:ExpParams
	SVAR TTL_PARAMS

	String controlNames = ControlNameList("Pulse")
	Print(controlNames)
	Variable i = 0
	Variable ScanOrder = 1
	
	String scanned = ""
	do
		String ctrlName = StringFromList(i,controlNames)

		if(strlen(ctrlName) == 0)
			break
		endif
		if(GrepString(ctrlName,"Step[0-9]+Scan[0-9]+"))
			String numStep, numScan
			SplitString/E="Step([0-9]+)Scan([0-9]+)" ctrlName, numStep, numScan			
			Variable loadID = str2num(numStep)-1
			Variable scanID = str2num(numScan)

			Variable beenScanned = 0
			// This next code block makes sure that frequency sources are only scanned once per experiment
			if(scanID == 0) // only check once per step
				// we now want to make sure that the id in question describes frequency source(s)
				Variable ttlType = load[loadID][0]
				String ttlparam = StringFromList(ttlType, TTL_PARAMS)
				if(!stringmatch(ttlparam,"") && str2num(ttlparam) > 0) // make sure ttlparam is not either 0 or empty
					// if it isn't 0/empty, it can only be scanned once! (except for duration)
					print scanned
					if(stringmatch(ListMatch(scanned, num2str(ttlType)), "")) // if it's already been scanned, mark it as so
						scanned += num2str(ttlType) + ";"
					else
						beenScanned = 1
					endif
				endif
			endif
			
			ControlInfo $ctrlName
			switch(scanID)
				case 0:
					SetVariable $("Step"+numStep+"setpoint0"), pos={340, V_top}, title="Time Duration (us)", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=SettingWave[7*i+1][1]
					if(V_Value == 1)
						SetVariable $("Step"+numStep+"lowerlim0"), pos={540, V_top}, title="Start Duration (us)", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=SettingWave[7*i+1][2]
						SetVariable $("Step"+numStep+"upperlim0"), pos={740, V_top}, title="End Duration (us)", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=SettingWave[7*i+1][3]
						SetVariable $("Step"+numStep+"inc0"), pos={940, V_top}, title="Increment (us)", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=SettingWave[7*i+1][4]
						SetVariable $("Step"+numStep+"ScanOrder0"), pos={1080, V_top}, title="Scan Order", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=SettingWave[7*i+1][5]
						SettingWave[7*i+1][5] = ScanOrder
						ScanOrder+=1
					endif
				break
				case 1:
					SetVariable $("Step"+numStep+"setpoint1"), pos={340, V_top}, title="AO Frequency (MHZ)", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+2][1]
					if(beenScanned == 0 && V_Value == 1) 
						SetVariable $("Step"+numStep+"lowerlim1"), pos={540, V_top}, title="Start AO Frequency (MHZ)", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+2][2]
						SetVariable $("Step"+numStep+"upperlim1"), pos={740, V_top}, title="End AO Frequency (MHZ)", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+2][3]
						SetVariable $("Step"+numStep+"inc1"), pos={940, V_top}, title="Increment (MHZ)", win=Pulse,size={130,20},bodywidth=50,limits={0.001,400,.001},value=SettingWave[7*i+2][4]
						SetVariable $("Step"+numStep+"ScanOrder1"), pos={1080, V_top}, title="Scan Order", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=SettingWave[7*i+2][5]
						SettingWave[7*i+2][5] = ScanOrder
						ScanOrder+=1
					endif
				break
				case 2:
					SetVariable $("Step"+numStep+"setpoint2"), pos={340, V_top}, title="AO Amplitude", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+3][1]
					if(beenScanned == 0 && V_Value == 1) 
						SetVariable $("Step"+numStep+"lowerlim2"), pos={540, V_top}, title="Start AO Amplitude", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+3][2],limits={0,1023,1}
						SetVariable $("Step"+numStep+"upperlim2"), pos={740, V_top}, title="End AO Amplitude (MHZ)", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+3][3],limits={0,1023,1}
						SetVariable $("Step"+numStep+"inc2"), pos={940, V_top}, title="Increment", win=Pulse,size={130,20},bodywidth=50,limits={1,1023,1},value=SettingWave[7*i+3][4]
						SetVariable $("Step"+numStep+"ScanOrder2"), pos={1080, V_top}, title="Scan Order", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=SettingWave[7*i+3][5]
						SettingWave[7*i+3][5] = ScanOrder
						ScanOrder+=1
					endif
				break
				case 3:
					SetVariable $("Step"+numStep+"setpoint3"), pos={340, V_top}, title="AO Phase", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+4][1]
					if(beenScanned == 0 && V_Value == 1) 
						SetVariable $("Step"+numStep+"lowerlim3"), pos={540, V_top}, title="Start AO Phase", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+4][2]
						SetVariable $("Step"+numStep+"upperlim3"), pos={740, V_top}, title="End AO Phase", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+4][3]
						SetVariable $("Step"+numStep+"inc3"), pos={940, V_top}, title="Increment (Degrees)", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=SettingWave[7*i+4][4]
						SetVariable $("Step"+numStep+"ScanOrder3"), pos={1080, V_top}, title="Scan Order", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=SettingWave[7*i+4][5]
						SettingWave[7*i+4][5] = ScanOrder
						ScanOrder+=1
					endif
				break
				case 4:
					SetVariable $("Step"+numStep+"setpoint4"), pos={340, V_top}, title="EO Frequency (MHz)", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+5][1]
					if(beenScanned == 0 && V_Value == 1) 
						SetVariable $("Step"+numStep+"lowerlim4"), pos={540, V_top}, title="Start EO Frequency (MHz)", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+5][2]
						SetVariable $("Step"+numStep+"upperlim4"), pos={740, V_top}, title="End EO Frequency", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+5][3]
						SetVariable $("Step"+numStep+"inc4"), pos={940, V_top}, title="Increment (MHz)", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=SettingWave[7*i+5][4]
						SetVariable $("Step"+numStep+"ScanOrder4"), pos={1080, V_top}, title="Scan Order", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=SettingWave[7*i+5][5]
						SettingWave[7*i+5][5] = ScanOrder
						ScanOrder+=1
					endif
				break
				case 5:
					SetVariable $("Step"+numStep+"setpoint5"), pos={340, V_top}, title="EO Amplitude", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+6][1]
					if(beenScanned == 0 && V_Value == 1) 
						SetVariable $("Step"+numStep+"lowerlim5"), pos={540, V_top}, title="Start EO Amplitude", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+6][2]
						SetVariable $("Step"+numStep+"upperlim5"), pos={740, V_top}, title="End EO Amplitude", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+6][3]
						SetVariable $("Step"+numStep+"inc5"), pos={940, V_top}, title="Increment", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=SettingWave[7*i+6][4]
						SetVariable $("Step"+numStep+"ScanOrder5"), pos={1080, V_top}, title="Scan Order", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=SettingWave[7*i+6][5]
						SettingWave[7*i+6][5] = ScanOrder
						ScanOrder+=1
					endif
				break
				case 6:
					SetVariable $("Step"+numStep+"setpoint6"), pos={340, V_top}, title="Rotation Amplitude", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+7][1]
					if(beenScanned == 0 && V_Value == 1) 
						SetVariable $("Step"+numStep+"lowerlim6"), pos={540, V_top}, title="Start Rotation Amplitude", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+7][2]
						SetVariable $("Step"+numStep+"upperlim6"), pos={740, V_top}, title="End Rotation Amplitude", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+7][3]
						SetVariable $("Step"+numStep+"inc6"), pos={940, V_top}, title="Increment", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=SettingWave[7*i+7][4]
						SetVariable $("Step"+numStep+"ScanOrder6"), pos={1080, V_top}, title="Scan Order", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=SettingWave[7*i+7][5]
						SettingWave[7*i+7][5] = ScanOrder
						ScanOrder+=1
					endif
				break
				case 7:
					SetVariable $("Step"+numStep+"setpoint7"), pos={340, V_top}, title="Rotation Freq (MHz)", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+8][1]
					if(beenScanned == 0 && V_Value == 1) 
						SetVariable $("Step"+numStep+"lowerlim7"), pos={540, V_top}, title="Start Rotation Freq (MHz)", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+8][2]
						SetVariable $("Step"+numStep+"upperlim7"), pos={740, V_top}, title="End Rotation Freq (MHz)", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+8][3]
						SetVariable $("Step"+numStep+"inc7"), pos={940, V_top}, title="Increment", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=SettingWave[7*i+8][4]
						SetVariable $("Step"+numStep+"ScanOrder7"), pos={1080, V_top}, title="Scan Order", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=SettingWave[7*i+8][5]
						SettingWave[7*i+8][5] = ScanOrder
						ScanOrder+=1
					endif
				break
				case 8:
					SetVariable $("Step"+numStep+"setpoint8"), pos={340, V_top}, title="Rotation Phase", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+9][1]
					if(beenScanned == 0 && V_Value == 1) 
						SetVariable $("Step"+numStep+"lowerlim8"), pos={540, V_top}, title="Start Rotation Phase", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+9][2]
						SetVariable $("Step"+numStep+"upperlim8"), pos={740, V_top}, title="End Rotation Phase", win=Pulse,size={130,20},bodywidth=50,value=SettingWave[7*i+9][3]
						SetVariable $("Step"+numStep+"inc8"), pos={940, V_top}, title="Increment", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=SettingWave[7*i+9][4]
						SetVariable $("Step"+numStep+"ScanOrder8"), pos={1080, V_top}, title="Scan Order", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=SettingWave[7*i+9][5]
						SettingWave[7*i+9][5] = ScanOrder
						ScanOrder+=1
					endif
				break
				default: 		// Bad parameter in lookup table!
					Print "Bad parameter in lookup table!" 
			endswitch
		endif
		i+=1
	while(1)

End

//_____________________________________________________________________________
//
//	Creates set scan, clear scan, and run buttons and the cycles #
//_____________________________________________________________________________
//
Function CreateButtons()
	SetDataFolder root:ExpParams
	NVAR VerticalButtonPosition
	
	SetVariable Loops pos={542,VerticalButtonPosition},win=Pulse,title="Data Point Loop", limits={0,65535,1}, size={150,20},value=_NUM:10
	SetVariable Times pos={700,VerticalButtonPosition},win=Pulse,title="Experimental Loop", limits={0,2^16,1}, size={150,20},value=_NUM:1
	
	VerticalButtonPosition+=30
	
	//Button LoadSettings win=Pulse, pos={15,VerticalButtonPosition}, title="Load Settings", proc=LoadSettingsProc ,size={100,20}
	Button SaveSettings win=Pulse, pos={15,VerticalButtonPosition}, title="Save Settings", proc=SaveSettingsProc, size={100,20}
	PopupMenu LoadSettings,pos={155,VerticalButtonPosition},size={202,21},bodyWidth=150,proc=LoadSettingsPopMenuProc,title="Load:",mode=1,value=LoadSettingsList()
	Button Run win=Pulse,pos={575,VerticalButtonPosition}, title="Run", proc=RunProc,size={100,20}
	CheckBox TDCbox win=Pulse,pos={683,VerticalButtonPosition}, title="TDC on/off",variable=TDC
End

function/S LoadSettingsList()
	String SequenceName = ""
	String SettingNames = ""
	ControlInfo/W=Pulse Sequence
	SequenceName=S_Value	
	String SettingsDataFolderPath	= "root:Settings:"+SequenceName
	if (DataFolderExists(SettingsDataFolderPath))
		SetDataFolder $(SettingsDataFolderPath)
		Variable numSavedSequences = CountObjects("", 3)
		Variable idx
		for (idx = 0; idx < numSavedSequences; idx+=1)
			SettingNames+=GetIndexedObjName("", 3, idx) + ";"
		endfor
	endif
	
	return SettingNames
end


//_____________________________________________________________________________
//
//	Procedures for Load Settings Button - loads the scan bounds and checkboxes from file
//_____________________________________________________________________________
//
Function LoadSettingsProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	String SequenceName, SettingNames
	
	switch(ba.eventCode)
		case 2: //mouse up
			ControlInfo/W=Pulse Sequence
			SequenceName=S_Value	
			String SettingsDataFolderPath	= "root:Settings:"+SequenceName
			if (DataFolderExists(SettingsDataFolderPath))
				SetDataFolder $(SettingsDataFolderPath)
				Variable numSavedSequences = CountObjects("", 1)
				Variable idx
				for (idx = 0; idx < numSavedSequences; idx+=1)
					SettingNames+=";"+GetIndexedObjName("", 1, idx)
				endfor
			else
				Abort "Sequence type not found. Run re-initialization."
			endif
	
	//print numSavedSequences
	//WAVE/T SavedSequences = root:ExpParams:SavedSequences
	String names = " "
	
			
//			// Get settings path name and convert it to a string
//			PathInfo SettingsPath
//			String SettingsPathStr = S_path
//			// Make sure a folder delimiter is at the end
//			SettingsPathStr = ParseFilePath(2, SettingsPathStr, ":", 0, 0)
//			// Create a new settings path based on the name of the saved sequence
//			NewPath/C/O/Q TempSettingsPath, SettingsPathStr+SequenceName+":"
//			LoadWave/P=TempSettingsPath/T/O/A=LoadedScan
			
			break
		case -1:
			break
	endswitch
End

//_____________________________________________________________________________
//
//	LoadScanSettings() loads previously saved scan settings
//_____________________________________________________________________________
//
//Function/WAVE LoadScanSettings()
//	SetDataFolder root:ExpParams	
//	WAVE wave0
//
//	Variable SequenceNum
//	ControlInfo Sequence
//	SequenceNum=V_Value-1
//	String SequenceName = S_Value
//	
//	// Get settings path name and convert it to a string
//	PathInfo SettingsPath
//	String SettingsPathStr = S_path
//	// Make sure a folder delimiter is at the end
//	SettingsPathStr = ParseFilePath(2, SettingsPathStr, ":", 0, 0)+SequenceName
//	NewPath/O/Q InitialSettingsPath SettingsPathStr
//	if (V_flag == 0) 
//		String Loadwavestring="LoadWave/O/D/H/J/M/N/G/P=InitialSettingsPath"
//		Execute Loadwavestring
//	else
//		Print "Error finding scan settings"
//	endif
//	Return wave0
//End

//_____________________________________________________________________________
//
//	Procedures for Save Settings Button - Saves current scan bounds and checkboxes
//_____________________________________________________________________________
//
Function SaveButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NewDataFolder/O/S root:Settings
	String SequenceName
	switch(ba.eventCode)
		case 2: //mouse up
			ControlInfo/W=SaveSettingsWindow SequenceNamefield
			String SettingName=S_Value
			ControlInfo/W=Pulse Sequence
			SequenceName=S_Value
			NewDataFolder/O/S $("root:Settings:"+SequenceName)
			
			// This is where the code to implement saving settings would go. Maybe simply try 
			// exporting in JSON format to a string variable instead of to a file
			STRUCT Experiment expt
			GetExperiment(expt)
			GetExperimentParameters(expt)
			String exptJSONstr = ExportExptToJSONString(expt)
			print SettingName
			String/G $("root:Settings:"+SequenceName+":"+SettingName) = exptJSONstr
//			// Must make temporary local wave reference for programmatically-generated 
//			// Igor variable names
//			Make/O/T $(SettingName)
//			Wave/T settingWaveReference = $(SettingName)		
//					
//			String controlNames = ControlNameList("Pulse")
//			Variable k = 0
//			do
//				String ctrlName = StringFromList(k,controlNames)
//				if(strlen(ctrlName) == 0)
//					break
//				endif				
//				ControlInfo/W=Pulse $ctrlName
//				settingWaveReference[k] = S_recreation
//				k += 1
//			while(1)		
			DoWindow/K SaveSettingsWindow	
			break
		case -1:			
			break
	endswitch
End

//_____________________________________________________________________________
//
//	Procedures for Save Settings Button - Saves current scan bounds and checkboxes
//_____________________________________________________________________________
//
Function SaveSettingsProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch(ba.eventCode)
		case 2: //mouse up
			PauseUpdate; Silent 1		// building window...
			NewPanel/N=SaveSettingsWindow/K=0/W=(806,108,1138,208) as "Save Settings as..."
			SetVariable SequenceNamefield pos={100,17.5},size={195,20},BodyWidth=185,title="Settings Name:",value=_STR:"SettingsName"
			Button WaveSaveButton pos={197.5,57.5},size={100,20},title="Save Sequence",proc=SaveButtonProc		
			break
		case -1:
			
			break
	endswitch
End

//_____________________________________________________________________________
//
// SaveButtonProc(ba) : ButtonControl
//_____________________________________________________________________________
//
//Function SaveButtonProcOLD(ba) : ButtonControl
//	STRUCT WMButtonAction &ba
//	setdatafolder root:ExpParams
//	SVAR ScanControlRecreator
//	WAVE ScanParams
//	Variable SequenceNum
//	String SequenceName
//	ControlInfo/W=Pulse Sequence
//	SequenceNum=V_Value
//	String SettingName,MakePath
//	String SaveSettingsstring
//	switch(ba.eventCode)
//		case 2: //mouse up
//			ControlInfo/W=SaveSettingsWindow SequenceNamefield
//			SettingName=S_Value
//			ControlInfo/W=Pulse Sequence
//			SequenceName=S_Value
//		
//			// Get settings path name and convert it to a string
//			PathInfo SettingsPath
//			String SettingsPathStr = S_path
//			// Make sure a folder delimiter is at the end
//			SettingsPathStr = ParseFilePath(2, SettingsPathStr, ":", 0, 0)
//			// Create a new settings path based on the name of the saved sequence
//			NewPath/C/O/Q TempSettingsPath, SettingsPathStr+SequenceName+":"
//			//Variable f1 //make refNum variable
//			SettingName+=".dat"
//			//Open/P=TempSettingsPath f1 as SettingName //create and open file
//			
//			
//			Make/O/T RecreateScanControls
//			//ScanControlRecreator = ""
//			String controlNames = ControlNameList("Pulse")
//			Variable k = 0
//			do
//				String ctrlName = StringFromList(k,controlNames)
//				if(strlen(ctrlName) == 0)
//					break
//				endif				
//				ControlInfo/W=Pulse $ctrlName
//				//Print S_recreation
//				//ScanControlRecreator += S_recreation
//				RecreateScanControls[k] = S_recreation
//			k += 1
//			while(1)	
//			
//			//fprintf f1, "%s", ScanControlRecreator 
//			//Close f1 //close file
//			
//			Save/T/P=TempSettingsPath/O/G/W RecreateScanControls as SettingName 
//			 
//			//Save/P=TempSettingsPath/O/G/W ScanParams as SettingName+".dat"
//			DoAlert/T="Save Message" 0, "Settings Saved"
//			DoWindow/K SaveSettingsWindow
//			break
//		case -1:			
//			break
//	endswitch
//End

//_____________________________________________________________________________
//
//	SettingsCheck() determines if there is a problem with the experimental settings
//_____________________________________________________________________________
//
Function SettingsCheck()
	SetDataFolder root:ExpParams
	NVAR FixScanOrder
	NVAR SettingsCheckOut
	WAVE ScanParams
	Variable i,ii
	Variable Problem=0
	Variable Problem1=0
	
	For(i=0;i<FindTotalStep();i+=1)
		For(ii=0;ii<7;ii+=1)
			If(ScanParams[7*i+ii][4]!=0)
				If(Mod(ScanParams[7*i+ii][3]-ScanParams[7*i+ii][2],ScanParams[7*i+ii][4])!=0)
					Problem=1
					DoAlert/T="Fix Scan Parameters" 0,"Start and Stop Scan must be an integer number of increments apart"
					Break
				Endif
			Endif
		EndFor
		If(Problem==1)
			Break
		Endif
	EndFor
	Problem1=	CheckScanOrder()
	Return Mod(Problem+Problem1+Problem*Problem1,2)
End

//_____________________________________________________________________________
//
// SaveSettingsWindow()
//_____________________________________________________________________________
//
Window SaveSettingsWindow() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1/W=(806,108,1138,208) as "Save Settings as..."
	SetVariable SequenceNamefield pos={100,17.5},size={195,20},BodyWidth=185,title="Settings Name:",value=_STR:"SettingsName"
	Button WaveSaveButton pos={197.5,57.5},size={100,20},title="Save Sequence",proc=SaveButtonProc
EndMacro

//_____________________________________________________________________________
//
// SaveButtonProc(ba) : ButtonControl
//_____________________________________________________________________________
//
Function SaveButtonProcOLD(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	setdatafolder root:Expparams
	WAVE ScanParams
	Variable SequenceNum
	String SequenceName
	ControlInfo/W=Pulse Sequence
	SequenceNum=V_Value
	String SettingName,MakePath
	String SaveSettingsstring
	switch(ba.eventCode)
		case 2: //mouse up
			ControlInfo/W=SaveSettingsWindow SequenceNamefield
			SettingName=S_Value
			ControlInfo/W=Pulse Sequence
			SequenceName=S_Value
			// Get settings path name and convert it to a string
			PathInfo SettingsPath
			String SettingsPathStr = S_path
			// Make sure a folder delimiter is at the end
			SettingsPathStr = ParseFilePath(2, SettingsPathStr, ":", 0, 0)
			// Create a new settings path based on the name of the saved sequence
			NewPath/C/O/Q TempSettingsPath, SettingsPathStr+SequenceName+":"
			Save/P=TempSettingsPath/O/G/W ScanParams as SettingName+".dat"
			DoAlert/T="Save Message" 0, "Settings Saved"
			DoWindow/K SaveSettingsWindow
			break
		case -1:
			
			break
	endswitch
End

//_____________________________________________________________________________
//
//	Procedures for Run button - checks to make sure info is input correctly, then sends 
//	sequence to the fpga
//_____________________________________________________________________________
//
Function RunProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	setDatafolder root:ExpParams
	switch( ba.eventCode )	
		case 2: // mouse up
			STRUCT Experiment expt
			// Instantiate the Experiment structure with loaded sequence
			GetExperiment(expt)
			// Load the control and scan parameters into the Experiment structure
			GetExperimentParameters(expt)
			ConstructAWGWaveform(expt)
			// Export Experiment structure
			// String timeStampedFilename = getTimeStamp()+"_ExptStruct.txt"
			String timeStampedFilename = "CurrentExperiment.txt"
			ExportExptToJSONFile(expt, timeStampedFilename)
			break
		case -1:
			break
	endswitch	
End

//_____________________________________________________________________________
//
//	GetExperiment(expt) creates an Experiment structure based on the current sequence type
//_____________________________________________________________________________
//
function GetExperiment(expt)
	STRUCT Experiment &expt
	SetDataFolder root:ExpParams
	WAVE sequence = LoadedWave
	WAVE/T ExOpNames = TTLNames	
	Variable/G TotalStep	
	TotalStep=FindtotalStep()	
	Make/O/T/N=(TotalStep) ExpSeq = ""
	Variable k
	for (k=0;k<TotalStep;k+=1)
		ExpSeq[k] = ExOpNames[sequence[k]]
	endfor	

	BuildExperiment(ExpSeq, expt)
End

//_____________________________________________________________________________
//
//	GetExperimentParameters(expt) updates an existing Experiment structure with the 
//	control parameters and scan information from the sequence builder panel
//_____________________________________________________________________________
//
function GetExperimentParameters(expt)
	
	STRUCT Experiment &expt
	String windowName = "Pulse"
	Variable ExOpIdx = 0
	Variable ExOpParam	= 0
	Variable position = 0
	Variable state = 0
	Variable scanMin, scanMax, scanInc, checked
	Variable Value
	String numStep
	
	// Get list of all control names and iterate through each one, extracting the data
	// appropriate for the different kinds of controls, determined by parsing the control
	// name itself
	String controlNames = ControlNameList(windowName)
	Variable k = 0
	do
		String ctrlName = StringFromList(k,controlNames)
		if(strlen(ctrlName) == 0)
			break
		endif
		
		ControlInfo/W=$(windowName) $ctrlName

		if(GrepString(ctrlName,"Step[0-9]+position"))
			//KillControl/W=$(windowName) $ctrlName
			SplitString/E="[0-9]+" ctrlName
			ExOpIdx = str2num(S_Value)
			ControlInfo/W=$(windowName) $ctrlName
			position = V_Value
			expt.ExOps[ExOpIdx].Position = position
		endif
		// Extract the control parameter values and store in the Experiment structure. 
		// It would be better to create some utility function that writes specified elements 
		// in the semi-colon-separated control parameter string "array"
		if(GrepString(ctrlName,"Step[0-9]+setpoint[0-9]+"))
			//KillControl/W=$(windowName) $ctrlName
			SplitString/E="[0-9]+" ctrlName
			ExOpIdx = str2num(S_Value)
			SplitString/E="setpoint[0-9]+" ctrlName
			SplitString/E="[0-9]+" S_Value
			ExOpParam = str2num(S_Value)
			ControlInfo/W=$(windowName) $ctrlName
			Value = V_Value
			//printf "%s: ExOpIdx = %d, ExOpParam = %d, Value = %d\r" ctrlName, ExOpIdx, ExOpParam, Value
			if (ExOpParam == 0)
				expt.ExOps[ExOpIdx].Values = num2str(Value) + ";"
			else
				expt.ExOps[ExOpIdx].Values += num2str(Value) + ";"
			endif
		endif
		// Extract scan parameters. THE ORDER MATTERS, since GrepString(ctrlName,"Step[0-9]+Scan[0-9]+") 
		// also matches the check box controls
		if(GrepString(ctrlName,"Step[0-9]+Scan[0-9]+Min"))
			SplitString/E="Step[0-9]+" ctrlName
			SplitString/E="[0-9]+" S_Value
			ExOpIdx = str2num(S_Value)
			SplitString/E="Scan[0-9]+" ctrlName
			SplitString/E="[0-9]+" S_Value
			ExOpParam = str2num(S_Value)
			ControlInfo/W=$(windowName) $ctrlName
			scanMin = V_Value
			//printf "%s: ExOpIdx = %d, ExOpParam = %d, scanMin = %d\r" ctrlName, ExOpIdx, ExOpParam, scanMin
			expt.ExOps[ExOpIdx].Scanned = 1
			expt.ExOps[ExOpIdx].ScanParameter = ExOpParam
			expt.ExOps[ExOpIdx].ScanStart = scanMin			
		endif
		if(GrepString(ctrlName,"Step[0-9]+Scan[0-9]+Max"))
			SplitString/E="Step[0-9]+" ctrlName
			SplitString/E="[0-9]+" S_Value
			ExOpIdx = str2num(S_Value)
			SplitString/E="Scan[0-9]+" ctrlName
			SplitString/E="[0-9]+" S_Value
			ExOpParam = str2num(S_Value)
			ControlInfo/W=$(windowName) $ctrlName
			scanMax = V_Value
			//printf "%s: ExOpIdx = %d, ExOpParam = %d, scanMax = %d\r" ctrlName, ExOpIdx, ExOpParam, scanMax
			expt.ExOps[ExOpIdx].Scanned = 1
			expt.ExOps[ExOpIdx].ScanParameter = ExOpParam
			expt.ExOps[ExOpIdx].ScanStop = scanMax
		endif
		if(GrepString(ctrlName,"Step[0-9]+Scan[0-9]+Inc"))
			SplitString/E="Step[0-9]+" ctrlName
			SplitString/E="[0-9]+" S_Value
			ExOpIdx = str2num(S_Value)
			SplitString/E="Scan[0-9]+" ctrlName
			SplitString/E="[0-9]+" S_Value
			ExOpParam = str2num(S_Value)
			ControlInfo/W=$(windowName) $ctrlName
			scanInc = V_Value
			//printf "%s: ExOpIdx = %d, ExOpParam = %d, scanInc = %d\r" ctrlName,ExOpIdx, ExOpParam, scanInc
			expt.ExOps[ExOpIdx].Scanned = 1
			expt.ExOps[ExOpIdx].ScanParameter = ExOpParam
			expt.ExOps[ExOpIdx].ScanInc = scanInc
		endif
		if(GrepString(ctrlName,"Step[0-9]+Scan[0-9]+"))
			SplitString/E="Step[0-9]+" ctrlName
			SplitString/E="[0-9]+" S_Value
			ExOpIdx = str2num(S_Value)
			SplitString/E="Scan[0-9]+" ctrlName
			SplitString/E="[0-9]+" S_Value
			ExOpParam = str2num(S_Value)
			ControlInfo/W=$(windowName) $ctrlName
			checked = V_Value
			if ( !checked )
				expt.ExOps[ExOpIdx].Scanned = 0
			endif
		endif
		if(GrepString(ctrlName,"Loops"))
			ControlInfo/W=$(windowName) $ctrlName
			expt.exptsPerPoint = V_Value
		endif		
		if(GrepString(ctrlName,"Times"))
			ControlInfo/W=$(windowName) $ctrlName
			expt.pointsToAverage = V_Value
		endif		
		if(GrepString(ctrlName,"SBCoolingFreq[0-9]+"))
			ControlInfo/W=$(windowName) $ctrlName
			String val 
			sprintf val, "%g", V_Value
			SplitString/E="Step([0-9]+)SBCoolingFreq([0-9]+)" ctrlName, numStep
			expt.ExOps[str2num(numStep)].SBCFrequencies += val + ";"
		endif
		if(GrepString(ctrlName,"SBCoolingTime[0-9]+"))
			ControlInfo/W=$(windowName) $ctrlName
			SplitString/E="Step([0-9]+)SBCoolingTime([0-9]+)" ctrlName, numStep
			expt.ExOps[str2num(numStep)].SBCTimes += num2istr(V_Value) + ";"
		endif
		if(GrepString(ctrlName,"SBCoolingAmplitude[0-9]+"))
			ControlInfo/W=$(windowName) $ctrlName
			SplitString/E="Step([0-9]+)SBCoolingAmplitude([0-9]+)" ctrlName, numStep
			expt.ExOps[str2num(numStep)].SBCAmplitudes += num2istr(V_Value) + ";"
		endif
		if(GrepString(ctrlName,"SBCoolingCycles[0-9]+"))
			ControlInfo/W=$(windowName) $ctrlName
			SplitString/E="Step([0-9]+)SBCoolingCycles([0-9]+)" ctrlName, numStep
			expt.ExOps[str2num(numStep)].SBCCycles += num2istr(V_Value) + ";"
		endif		
		k+=1
	while(1)
	
	// Determine and set the Shuttled parameters
	for (ExOpIdx = 1; ExOpIdx < expt.numExOps; ExOpIdx +=1)
		if (expt.ExOps[ExOpIdx].Position != expt.ExOps[ExOpIdx-1].Position)
			expt.ExOps[ExOpIdx].Shuttled = 1
		endif
	endfor
	
	// Print the current Experiment structure state
	//	for (ExOpIdx = 0; ExOpIdx < expt.numExOps; ExOpIdx +=1)
	//		Print expt.ExOps[ExOpIdx]
	//	endfor
	//	Print expt.exptsPerPoint 
	//	Print expt.pointsToAverage
end

//_____________________________________________________________________________
//
//	Procedures for Run button - checks to make sure info is input correctly, then sends 
//	sequence to the fpga
//_____________________________________________________________________________
//
Function RunProcOLD(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	setDatafolder root:ExpParams
	WAVE LoadedWave
	NVAR SendCounter
	NVAR DDSnum,EOnum
	switch( ba.eventCode )	
		case 2: // mouse up
			GetScanParams()
			SendCounter=0			
			If (SettingsCheck()==0)
				Make/O/N=(FindMaxInc()*FindTotalScan()*GetExperimentalLoop(),FindTotalStep()+DDSnum+EOnum+1,4,GetDataPointLoop()*FindDataTakeNumber(LoadedWave)+1) sequencerData=0
				DefineValuesLooper()
				// StopTTL()
				UpdateTTL()
			Endif
			break
		case -1:
			break
	endswitch	
End


//Grabs the data from Scan Order for scanned parameters 
//Function GetScanOrder()
//	SetDatafolder root:ExpParams
//	NVAR TotalStep
//	WAVE LoadedWave
//	WAVE ScanParams
//	Variable i,ii
//	Variable/G exist
//	Variable/G exist0
//	Variable/G exist1
//	Variable/G exist2
//	Variable/G exist3
//	
//	For (i=0;i<TotalStep;i+=1)
//		If (LoadedWave[i][0]==1||LoadedWave[i][0]==2||LoadedWave[i][0]==3)
//		
//			String existscan0 = "ControlInfo Step"+num2str(i+1)+"ScanOrder0 ; exist0 =V_flag"
//			String existscan1 = "ControlInfo Step"+num2str(i+1)+"ScanOrder1 ; exist1 =V_flag"
//			String existscan2 = "ControlInfo Step"+num2str(i+1)+"ScanOrder2 ; exist2 =V_flag"
//			String existscan3 = "ControlInfo Step"+num2str(i+1)+"ScanOrder3 ; exist3 =V_flag"
//			
//			String getscan0 = "ControlInfo Step"+num2str(i+1)+"ScanOrder0 ; ScanParams["+num2str(5*1+1)+"][5]=V_Value"
//			String getscan1 = "ControlInfo Step"+num2str(i+1)+"ScanOrder1 ; ScanParams["+num2str(7*i+2)+"][5]=V_Value"
//			String getscan2 = "ControlInfo Step"+num2str(i+1)+"ScanOrder2 ; ScanParams["+num2str(7*i+3)+"][5]=V_Value"
//			String getscan3 = "ControlInfo Step"+num2str(i+1)+"ScanOrder3;  ScanParams["+num2str(7*i+4)+"][5]=V_Value"
//			
//			Execute existscan0
//			Execute existscan1
//			Execute existscan2
//			Execute existscan3
//			
//			If (exist0!=0)
//				Execute getscan0
//			Endif
//			If (exist1!=0)
//				Execute getscan1
//			Endif
//			If (exist2!=0)
//				Execute getscan2
//			Endif
//			If (exist3!=0)
//				Execute getscan3
//			Endif
//		Else
//			String existscan = "ControlInfo Step"+num2str(i+1)+"ScanOrder ; exist =V_flag"
//			
//			Execute existscan
//			
//			String getscan = "ControlInfo Step"+num2str(i+1)+"ScanOrder ; ScanParams["+num2str(7*i)+"][5]=V_Value"
//			
//			If (exist!=0)
//			
//				Execute getscan
//			Endif
//		Endif
//	EndFor
//End

//_____________________________________________________________________________
//
//	Checks to make sure the Scan Order doesn't skip a number
//_____________________________________________________________________________
//
Function CheckScanOrder()
	SetDataFolder root:ExpParams
	NVAR TotalStep
	NVAR TotalScan
	NVAR FixScanOrder
	WAVE LoadedWave
	WAVE ScanParams
	Variable i,ii
	Variable ScanCount=0
	
	TotalScan=FindTotalScan()
	
	FixScanOrder=0

	For (i=0;i<1024*7;i+=1)
		For (ii=1;ii<=TotalScan;ii+=1)
			if (ScanParams[i][5]==ii)
				Scancount+=1
				Break
			EndIf
		EndFor
	EndFor
	if (ScanCount!=FindTotalScan())
		DoAlert/T="Scan Order Error" 0, "Fix Scan Order"
		FixScanOrder=1
	Endif
	Return FixScanOrder
End

//_____________________________________________________________________________
//
//	TestPrint(loader,waver)
//_____________________________________________________________________________
//
Function TestPrint(loader,waver)
	WAVE loader
	WAVE waver
	SetDataFolder root:ExpParams
	Variable i,ii,iii
	
	For (i=0;i<FindTotalinStep(waver);i+=1)
		String stepper = "Print \"Step Number: "+num2str(i+1)+"\""
		Execute stepper
		For(ii=0;ii<7;ii+=1)
			String setter = "Print \"Set Number: "+num2str(ii+1)+"\""
			Execute setter
			For(iii=0;iii<6;iii+=1)
				Print loader[7*i+ii][iii]
			EndFor
		EndFor
	EndFor
End

//_____________________________________________________________________________
//
//	TestPrintVALS(loader)
//_____________________________________________________________________________
//
Function TestPrintVALS(loader)
	WAVE loader
	SetDataFolder root:ExpParams
	Variable i,ii
	
	For (i=0;i<FindTotalStep();i+=1)
		//Print("Step "+num2str(i+1))
		Print("Name "+num2str(loader[i][0]))
		Print("Duration "+num2str(loader[i][1]))
	EndFor
End

//_____________________________________________________________________________
//
//	TestPrintDDS(loader)
//_____________________________________________________________________________
//
Function TestPrintDDS(loader)
	WAVE loader
	SetDataFolder root:ExpParams
	Variable i,ii,iii
	
	For (i=0;i<3;i+=1)
		Print("DDS #"+num2str(loader[i][0]))
		For(ii=1;ii<4;ii+=1)
			Print(loader[i][ii])
		EndFor
	EndFor
End

//_____________________________________________________________________________
//
//	Loads scan parameters or set points into Wave
//_____________________________________________________________________________
//
Function GetScanParams()
	SetDataFolder root:ExpParams
	WAVE LoadedWave
	WAVE ScanParams
	WAVE Settings
	NVAR TotalStep
	NVAR value0,value1,value2,value3
	NVAR DDS1Counter,DDS2Counter,DDS3Counter,DDS7Counter,DDS8Counter,DDSCounted
	String DDSCounter
	
	DDS1Counter=0
	DDS2Counter=0
	DDS3Counter=0
	DDS7Counter=0
	DDS8Counter=0
	DDSCounted=0
	TotalStep=FindtotalStep()
	
	Variable i,ii,iii
	
	String/G GetSetPoint,GetLowerLim,GetUpperLim,GetInc,GetScan,GetCheck
	
	ScanParams=0
	For (i=0;i<TotalStep;i+=1)
		value0=0
		value1=0
		value2=0
		value3=0
		If (LoadedWave[i][0]==1||LoadedWave[i][0]==7||LoadedWave[i][0]==8)
			DDScounter="DDS"+num2str(LoadedWave[i][0])+"Counter+=1;DDSCounted=DDS"+num2str(LoadedWave[i][0])+"Counter"
			Execute DDSCounter
			If(DDSCounted<2)
				For(ii=1;ii<5;ii+=1)
					Getcheck="ControlInfo Step"+num2str(i+1)+"Scan"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][0]=V_Value"
					Execute Getcheck
					If(ScanParams[7*i+ii][0]==1)
						GetSetPoint = "ControlInfo Step"+num2str(i+1)+"SetPoint"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][1]=V_Value"
						GetLowerLim = "ControlInfo Step"+num2str(i+1)+"LowerLim"+num2str(ii-1)+" ;  ScanParams["+num2str(7*i+ii)+"][2]=V_Value"
						GetUpperLim = "ControlInfo Step"+num2str(i+1)+"UpperLim"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][3]=V_Value"
						GetInc = "ControlInfo Step"+num2str(i+1)+"Inc"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][4]=V_Value"
						GetScan = "ControlInfo Step"+num2str(i+1)+"ScanOrder"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][5]=V_Value"
						
						Execute GetSetPoint
						Execute GetLowerLim
						Execute GetUpperLim
						Execute GetInc
						Execute GetScan
						
					Else
						GetSetPoint = "ControlInfo Step"+num2str(i+1)+"SetPoint"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][1]=V_Value"
						Execute GetSetPoint
						
						For (iii=2;iii<5;iii+=1)
							ScanParams[7*i+ii][iii]=Settings[7*i+ii][iii]
						EndFor
						
					Endif
				EndFor
			Else
				ii=1
				Getcheck="ControlInfo Step"+num2str(i+1)+"Scan"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][0]=V_Value"
				Execute Getcheck
				If(ScanParams[7*i+ii][0]==1)
					GetSetPoint = "ControlInfo Step"+num2str(i+1)+"SetPoint"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][1]=V_Value"
					GetLowerLim = "ControlInfo Step"+num2str(i+1)+"LowerLim"+num2str(ii-1)+" ;  ScanParams["+num2str(7*i+ii)+"][2]=V_Value"
					GetUpperLim = "ControlInfo Step"+num2str(i+1)+"UpperLim"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][3]=V_Value"
					GetInc = "ControlInfo Step"+num2str(i+1)+"Inc"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][4]=V_Value"
					GetScan = "ControlInfo Step"+num2str(i+1)+"ScanOrder"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][5]=V_Value"
					
					Execute GetSetPoint
					Execute GetLowerLim
					Execute GetUpperLim
					Execute GetInc
					Execute GetScan
					
				Else
					GetSetPoint = "ControlInfo Step"+num2str(i+1)+"SetPoint"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][1]=V_Value"
					Execute GetSetPoint
					
					For (iii=2;iii<5;iii+=1)
						ScanParams[7*i+ii][iii]=Settings[7*i+ii][iii]
					EndFor
					
				Endif
				
			
			Endif
		Elseif(LoadedWave[i][0]==10)
			DDScounter="DDS"+num2str(LoadedWave[i][0])+"Counter+=1;DDSCounted=DDS"+num2str(LoadedWave[i][0])+"Counter"
			Execute DDSCounter
			If(DDSCounted<2)
				For(ii=1;ii<7;ii+=1)
					If(ii==2)
						ii+=2
					Endif
					Getcheck="ControlInfo Step"+num2str(i+1)+"Scan"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][0]=V_Value"
					Execute Getcheck
					If(ScanParams[7*i+ii][0]==1)
						GetSetPoint = "ControlInfo Step"+num2str(i+1)+"SetPoint"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][1]=V_Value"
						GetLowerLim = "ControlInfo Step"+num2str(i+1)+"LowerLim"+num2str(ii-1)+" ;  ScanParams["+num2str(7*i+ii)+"][2]=V_Value"
						GetUpperLim = "ControlInfo Step"+num2str(i+1)+"UpperLim"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][3]=V_Value"
						GetInc = "ControlInfo Step"+num2str(i+1)+"Inc"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][4]=V_Value"
						GetScan = "ControlInfo Step"+num2str(i+1)+"ScanOrder"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][5]=V_Value"
						
						Execute GetSetPoint
						Execute GetLowerLim
						Execute GetUpperLim
						Execute GetInc
						Execute GetScan
						
					Else
						GetSetPoint = "ControlInfo Step"+num2str(i+1)+"SetPoint"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][1]=V_Value"
						Execute GetSetPoint
						
						For (iii=2;iii<5;iii+=1)
							ScanParams[7*i+ii][iii]=Settings[7*i+ii][iii]
						EndFor
						
					Endif
				EndFor
			Else
				ii=1
				Getcheck="ControlInfo Step"+num2str(i+1)+"Scan"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][0]=V_Value"
				Execute Getcheck
				If(ScanParams[7*i+ii][0]==1)
					GetSetPoint = "ControlInfo Step"+num2str(i+1)+"SetPoint"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][1]=V_Value"
					GetLowerLim = "ControlInfo Step"+num2str(i+1)+"LowerLim"+num2str(ii-1)+" ;  ScanParams["+num2str(7*i+ii)+"][2]=V_Value"
					GetUpperLim = "ControlInfo Step"+num2str(i+1)+"UpperLim"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][3]=V_Value"
					GetInc = "ControlInfo Step"+num2str(i+1)+"Inc"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][4]=V_Value"
					GetScan = "ControlInfo Step"+num2str(i+1)+"ScanOrder"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][5]=V_Value"
					
					Execute GetSetPoint
					Execute GetLowerLim
					Execute GetUpperLim
					Execute GetInc
					Execute GetScan
					
				Else
					GetSetPoint = "ControlInfo Step"+num2str(i+1)+"SetPoint"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][1]=V_Value"
					Execute GetSetPoint
					
					For (iii=2;iii<5;iii+=1)
						ScanParams[7*i+ii][iii]=Settings[7*i+ii][iii]
					EndFor
					
				Endif
				
			
			Endif
		
		Elseif(LoadedWave[i][0]==2||LoadedWave[i][0]==3)
			DDScounter="DDS"+num2str(LoadedWave[i][0])+"Counter+=1;DDSCounted=DDS"+num2str(LoadedWave[i][0])+"Counter"
			Execute DDSCounter
			If(DDSCounted<2)
				For(ii=1;ii<7;ii+=1)
					Getcheck="ControlInfo Step"+num2str(i+1)+"Scan"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][0]=V_Value"
					Execute Getcheck
					If(ScanParams[7*i+ii][0]==1)
						GetSetPoint = "ControlInfo Step"+num2str(i+1)+"SetPoint"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][1]=V_Value"
						GetLowerLim = "ControlInfo Step"+num2str(i+1)+"LowerLim"+num2str(ii-1)+" ;  ScanParams["+num2str(7*i+ii)+"][2]=V_Value"
						GetUpperLim = "ControlInfo Step"+num2str(i+1)+"UpperLim"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][3]=V_Value"
						GetInc = "ControlInfo Step"+num2str(i+1)+"Inc"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][4]=V_Value"
						GetScan = "ControlInfo Step"+num2str(i+1)+"ScanOrder"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][5]=V_Value"
						
						Execute GetSetPoint
						Execute GetLowerLim
						Execute GetUpperLim
						Execute GetInc
						Execute GetScan
						
					Else
						GetSetPoint = "ControlInfo Step"+num2str(i+1)+"SetPoint"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][1]=V_Value"
						Execute GetSetPoint
						
						For (iii=2;iii<5;iii+=1)
							ScanParams[7*i+ii][iii]=Settings[7*i+ii][iii]
						EndFor
						
					Endif
				EndFor
			Else
				ii=1
				Getcheck="ControlInfo Step"+num2str(i+1)+"Scan"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][0]=V_Value"
				Execute Getcheck
				If(ScanParams[7*i+ii][0]==1)
					GetSetPoint = "ControlInfo Step"+num2str(i+1)+"SetPoint"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][1]=V_Value"
					GetLowerLim = "ControlInfo Step"+num2str(i+1)+"LowerLim"+num2str(ii-1)+" ;  ScanParams["+num2str(7*i+ii)+"][2]=V_Value"
					GetUpperLim = "ControlInfo Step"+num2str(i+1)+"UpperLim"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][3]=V_Value"
					GetInc = "ControlInfo Step"+num2str(i+1)+"Inc"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][4]=V_Value"
					GetScan = "ControlInfo Step"+num2str(i+1)+"ScanOrder"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][5]=V_Value"
					
					Execute GetSetPoint
					Execute GetLowerLim
					Execute GetUpperLim
					Execute GetInc
					Execute GetScan
					
				Else
					GetSetPoint = "ControlInfo Step"+num2str(i+1)+"SetPoint"+num2str(ii-1)+" ; ScanParams["+num2str(7*i+ii)+"][1]=V_Value"
					Execute GetSetPoint
					
					For (iii=2;iii<5;iii+=1)
						ScanParams[7*i+ii][iii]=Settings[7*i+ii][iii]
					EndFor
					
				Endif
				
			
			Endif
			
		Else
			Getcheck="ControlInfo Step"+num2str(i+1)+"Scan; ScanParams["+num2str(7*i)+"][0]=V_Value"
			Execute Getcheck
			If (ScanParams[7*i][0]==1)
				GetSetPoint = "ControlInfo Step"+num2str(i+1)+"SetPoint; ScanParams["+num2str(7*i)+"][1]=V_Value"
				GetLowerLim = "ControlInfo Step"+num2str(i+1)+"LowerLim; ScanParams["+num2str(7*i)+"][2]=V_Value"
				GetUpperLim = "ControlInfo Step"+num2str(i+1)+"UpperLim; ScanParams["+num2str(7*i)+"][3]=V_Value"
				GetInc = "ControlInfo Step"+num2str(i+1)+"Inc; ScanParams["+num2str(7*i)+"][4]=V_Value"
				GetScan = "ControlInfo Step"+num2str(i+1)+"ScanOrder ; ScanParams["+num2str(7*i)+"][5]=V_Value"
				
				
				Execute GetSetPoint
				Execute GetLowerLim
				Execute GetUpperLim
				Execute GetInc
				Execute GetScan
			Else
				GetSetPoint = "ControlInfo Step"+num2str(i+1)+"SetPoint; ScanParams["+num2str(7*i)+"][1]=V_Value"
				Execute GetSetPoint
				For (iii=2;iii<5;iii+=1)
					ScanParams[7*i][iii]=Settings[7*i][iii]
				EndFor
				
			Endif
		Endif
		
	EndFor
End

////Tests if sequence is too long for FPGA ** not being used due to loops
//Function TestSequenceLength()
//	SetDatafolder root:ExpParams
//	WAVE ScanParams
//	WAVE LoadedWave
//	NVAR StepN
//	NVAR GroupMultiplier
//	NVAR TooLong
//
//	Variable TotalSize=0
//	Variable GroupSize=1
//	Variable CurrentGroup=1
//	Variable i	
//	
//	ControlInfo Loops
//	GroupMultiplier*=V_Value
//		
//	TooLong=0
//	For (i=0;i<StepN-1;i+=1)
//		if (LoadedWave[i+1][1]==LoadedWave[i][1])
//			GroupSize+=1
//		Else
//			TotalSize+=GroupSize*LoadedWave[CurrentGroup-1][2]
//			CurrentGroup+=1
//			GroupSize=1
//		Endif
//	EndFor
//	TotalSize+=GroupSize*LoadedWave[CurrentGroup-1][2]
//	TotalSize*=GroupMultiplier
//	If (TotalSize>1024)
//		DoAlert/T="Sequence Length Problem" 0, "Sequence Is Too Long"
//		TooLong=1
//	Endif
//End

//Determines time duration for given step given iteration number and scan number
//iteration starts at 0
//
//Function GetCurrentTime(step,iteration,ScanNum)
//	Variable step,iteration,ScanNum
//	SetDataFolder root:ExpParams
//	WAVE ScanParams
//	Variable returntime=0
//	
//	If (ScanParams[step*5][0]==0&&ScanParams[step*5+1][0]==0)
//		If (ScanParams[step*5+1][1]==0)
//			returntime=ScanParams[step*5][1]/0.02
//		Else
//			returntime=ScanParams[step*5+1][1]/0.02
//		Endif
//	Endif
//	If (ScanParams[step*5][0]==1&&ScanParams[step*5+1][0]==0)
//		If (ScanParams[step*5][5]==ScanNum)	
//			If (ScanParams[step*5][2]+ScanParams[step*5][4]*iteration>=ScanParams[step*5][3])
//				returntime=ScanParams[step*5][2]+ScanParams[step*5][4]*iteration
//			Else
//				DoAlert/T="Iteration Error" 0, "Coding Error GetCurrenttime() iteration too large"
//			Endif
//		Else
//			returntime = ScanParams[step*5][2]+( ScanParams[step*5][3]- ScanParams[step*5][2])/2
//		EndIf
//	Endif
//	If (ScanParams[step*5][0]==0&&ScanParams[step*5+1][0]==1)
//		If (ScanParams[step*5+1][5]==ScanNum)	
//			If (ScanParams[step*5+1][2]+ScanParams[step*5+1][4]*iteration>=ScanParams[step*5+1][3])
//				returntime=ScanParams[step*5+1][2]+ScanParams[step*5+1][4]*iteration
//			Else
//				DoAlert/T="Iteration Error" 0, "Coding Error GetCurrenttime() iteration too large"
//			endif
//		Else
//			returntime = ScanParams[step*5+1][2]+Floor(( ScanParams[step*5+1][3]- ScanParams[step*5+1][2])/(2*ScanParams[step*5+1][4]))*ScanParams[step*5+1][4]
//		EndIf
//	Endif
//	
//	return returntime
//
//End


//SetsDDS Parameters
//iteration starts at 0
//type 1=Cool, 2=State Detection, 3=flourescence detection
//If not on scan order, grabs values from DDS control panel
//Function SetDDSParams(iteration, ScanNum)
//	Variable iteration,ScanNum
//	SetDatafolder root:ExpParams
//	WAVE ScanParams
//	WAVE LoadedWave
//	WAVE DDS_INFO
//	
//	Variable ScanPosition
//	Variable i,ii
//	Variable dum1,dum2,dum3
//	
//	For (i=1;i<=3;i+=1)
//		For (ii=1;ii<=3;ii+=1)
//			if (LoadedWave[ii][0]==i)
//				ScanPosition=ii
//				break
//			Endif
//			setDDS(i-1, DDS_INFO[i-1][0]*10^6,DDS_INFO[i-1][1],DDS_INFO[i-1][2])
//		EndFor
//		For (ii=0;ii<3;ii+=1)
//			If (ScanParams[5*ScanPosition+2+ii][0]==0)
//				String grabset = "dum"+num2str(ii+1)+"=ScanParams[5*ScanPosition+2+"+num2str(ii)+"][1]"
//				Execute grabset
//			Else
//				If(ScanParams[5*ScanPosition+2+ii][5]!=ScanNum)
//					setDDS(i-1, DDS_INFO[i-1][0]*10^6,DDS_INFO[i-1][1],DDS_INFO[i-1][2])
//				Else
//					String grabit = "dum"+num2str(ii+1)+"=ScanParams[5*Position+2+"+num2str(ii)+"][2]+ScanParams[5*Position+2+"+num2str(ii)+"][4]*"+num2str(iteration)
//					Execute grabit
//				Endif
//			Endif
//			setDDS(i,dum1,dum2,dum3)
//		EndFor
//		
//	EndFor
//End


//_____________________________________________________________________________
//
//	DefaultSettings()
//_____________________________________________________________________________
//
Function/WAVE DefaultSettings()
	Make/O/N=(7*1024,6) settin
	WAVE LoadedWave
	NVAR TotalStep
	Variable i
	settin=0
	For(i=0;i<TotalStep;i+=1)
		If (LoadedWave[i][0]==1||LoadedWave[i][0]==7||LoadedWave[i][0]==8)
			settin[7*i+1][1]=1
			settin[7*i+1][2]=1
			settin[7*i+1][3]=5
			settin[7*i+1][4]=1
			settin[7*i+2][1]=200
			settin[7*i+2][2]=200
			settin[7*i+2][3]=220
			settin[7*i+2][4]=1
			settin[7*i+3][1]=100
			settin[7*i+3][2]=100
			settin[7*i+3][3]=500
			settin[7*i+3][4]=100
			settin[7*i+4][1]=0
			settin[7*i+4][2]=0
			settin[7*i+4][3]=45
			settin[7*i+4][4]=15
		Elseif (LoadedWave[i][0]==2||LoadedWave[i][0]==3)
			settin[7*i+1][1]=1
			settin[7*i+1][2]=1
			settin[7*i+1][3]=5
			settin[7*i+1][4]=1
			settin[7*i+2][1]=220
			settin[7*i+2][2]=220
			settin[7*i+2][3]=240
			settin[7*i+2][4]=1
			settin[7*i+3][1]=100
			settin[7*i+3][2]=100
			settin[7*i+3][3]=500
			settin[7*i+3][4]=100
			settin[7*i+4][1]=0
			settin[7*i+4][2]=0
			settin[7*i+4][3]=45
			settin[7*i+4][4]=15	
			settin[7*i+5][1]=2105
			settin[7*i+5][2]=2000
			settin[7*i+5][3]=2200
			settin[7*i+5][4]=100
			settin[7*i+6][1]=100
			settin[7*i+6][2]=100
			settin[7*i+6][3]=500
			settin[7*i+6][4]=100
		Elseif (LoadedWave[i][0]==10)
			settin[7*i+1][1]=1
			settin[7*i+1][2]=1
			settin[7*i+1][3]=5
			settin[7*i+1][4]=1
			settin[7*i+5][1]=3060
			settin[7*i+5][2]=3000
			settin[7*i+5][3]=3200
			settin[7*i+5][4]=100
			settin[7*i+6][1]=100
			settin[7*i+6][2]=100
			settin[7*i+6][3]=500
			settin[7*i+6][4]=100
		Else
			settin[7*i][1]=1
			settin[7*i][2]=1
			settin[7*i][3]=5
			settin[7*i][4]=1
		Endif
		
	EndFor
	
	Return settin
End

//_____________________________________________________________________________
//
//	Finds AND RETURNS the total number of steps in the loaded wave
//_____________________________________________________________________________
//
Function FindTotalStep()
	SetDataFolder root:ExpParams
	WAVE LoadedWave
	Variable TotalStep=0
	Variable i=0
	Do
		If(LoadedWave[i][1]!=0&&LoadedWave[i][1]!=10)
			TotalStep+=1
		Else
			Break
		Endif
		i+=1
	While(i<1024)
	Return TotalStep
End

//_____________________________________________________________________________
//
//	FindTotalinStep(in)
//_____________________________________________________________________________
//
Function FindTotalinStep(in)
	Wave in
	SetDataFolder root:ExpParams
	Variable TotalStep=0
	Variable i=0
	Do
		If(in[i][1]!=0)
			TotalStep+=1
		Else
			Break
		Endif
		i+=1
	While(i<1024)
	Return TotalStep
End

//_____________________________________________________________________________
//
//	FindTotalScan()
//_____________________________________________________________________________
//
Function FindTotalScan()
	SetDataFolder root:ExpParams
	WAVE ScanParams
	Variable i=0
	Variable count=0
	Do
		If (ScanParams[i][0]!=0)
			count+=1
		Endif
		i+=1
	While (i<1024*7)
	Return count
End

//_____________________________________________________________________________
//
//	Finds AND RETURNS Total number of steps to send to FPGA
//_____________________________________________________________________________
//
Function NumberofStepstoSend()
	SetDataFolder root:ExpParams
	WAVE LoadedWave
	Variable Totalcount=0
	Variable i=1
	Variable ii=1
	Variable iii=0 
	Do
		Totalcount+=FindGroupSize(i)*LoadedWave[i-1][2]
		i+=1
	While (i<=TotalGroupNumber())
	Return Totalcount
End


//_____________________________________________________________________________
//
//	Finds AND RETURNS total number of groups
//_____________________________________________________________________________
//
Function TotalGroupNumber()
	SetDatafolder root:ExpParams
	WAVE LoadedWave
	Variable i=0
	Variable TotalNumberofGroups=0
	Do
		i+=1
	While (LoadedWave[i][1]!=0)
	Return LoadedWave[i-1][1]
End


//_____________________________________________________________________________
//
//	Finds AND RETURNS the position of a given scan number  in the scanparams wave
//_____________________________________________________________________________
//
Function/D FindScanPos(ScanNum)
	Variable ScanNum
	SetDataFolder root:ExpParams
	WAVE ScanParams
	Variable i
	
	For (i=0; i<1024*7;i+=1)
		If (ScanParams[i][5]==ScanNum)
			break
		Endif
	EndFor
	return i
End


//_____________________________________________________________________________
//
//	finds AND RETURNS the size of the group number passed to the function
//_____________________________________________________________________________
//
Function FindGroupSize(grpNumber)
	Variable grpNumber
	SetDataFolder root:ExpParams
	WAVE LoadedWave
	
	Variable groupSize=0

	do
		groupSize+=1
	while (LoadedWave[FindFirstGroupElement(grpNumber)+groupSize][1]==grpNumber)
	
	return groupSize
	
End


//_____________________________________________________________________________
//
//	FindFirstGroupElement
//_____________________________________________________________________________
//
Function FindFirstGroupElement(groupNum)
	Variable groupNum
	SetDatafolder root:ExpParams
	WAVE LoadedWave
	Variable i=0
	Variable error=0
	
	If (groupNum>TotalGroupNumber())
		Print "Group Number Error"
	Endif
	do
		If(LoadedWave[i][1]==groupNum)
			Break
		endif
		i+=1
	While (i<FindTotalStep())
	
	If(Error==0)
		Return i
	Else
		Return -1
	Endif
End


//_____________________________________________________________________________
//
//	Need to finish writing this function
//	need to find value scanned over and write values accordingly
//	Do by conditional name==1,2,3
//	then if name==1,2,3 check if dds value scanned
//	write accordingly
//_____________________________________________________________________________
//
Function DefineValuesLooper()
	SetDataFolder root:ExpParams
	WAVE ScanParams
	WAVE LoadedWave
	Make/O/N=(3,4) DDSWAVE
	MAKE/O/N=(FindTotalStep(),2) VALWAVE
	Variable ScanCount=0
	Variable i
	Variable ii
	Variable Incrementer
	Variable outerloop=0
	Variable wat=0
	
	ControlInfo times
	outerloop=V_Value
	print outerloop
	
	
	//wat increments the experimental loop
	Do
		ScanCount=0
		//print "pass"
		If (FindTotalScan()>0)
			//Scancount increments through the total number of steps to scan
			Do
				Incrementer=0
				ii=0
				i=0
			
				GetScanParams()
				// i variable scans through steps to find the position of scancount in scan params and sets it equal to i (I guess this part is unneccesary)
				For (i=0;i<FindTotalStep();i+=1)
					If (i==floor(FindScanPos(ScanCount+1)/7))
						If(LoadedWave[i][0]==1||LoadedWave[i][0]==7||LoadedWave[i][0]==8)
							ii=1
							Do 
								If (ScanParams[7*i+ii][5]==ScanCount+1)
									Break
								Endif
								ii+=1
							While (ii<5)
							Do
								If (ii==1)
									SendtoFPGA(DefineValues(i,ii,incrementer),GrabDDSValues(-1,-1,-1),GrabMagiQValues(-1,-1,-1),i+ii/10,incrementer)//step number, substep, increment number//tells function to grab the setpoints for the DDS//sends to FPGA
									//	Print("Sent to SendtoFPGA: ")
									//	TestPrintVALS(DefineValues(i,ii,incrementer))
									//TestPrintDDS(GrabDDSValues(-1,-1,-1))						
								Else
							
									SendtoFPGA(DefineValues(-1,-1,-1),GrabDDSValues(i,ii,incrementer),GrabMagiQValues(-1,-1,-1),i+ii/10,incrementer)//Tells function to grab setpoints//step number, substep, imcrement number
								Endif
								incrementer+=1
							While (ScanParams[7*i+ii][4]*incrementer<=ScanParams[7*i+ii][3]-ScanParams[7*i+ii][2])
						Elseif(LoadedWave[i][0]==10)
							ii=1
							Do 
								If (ScanParams[7*i+ii][5]==ScanCount+1)
									Break
								Endif
								ii+=1
							While (ii<7)
							Do						
								SendtoFPGA(DefineValues(-1,-1,-1),GrabDDSValues(-1,-1,-1),GrabMagiQValues(i,ii,incrementer),i+ii/10,incrementer)//Tells function to grab setpoints//step number, substep, imcrement number
								incrementer+=1
							While (ScanParams[7*i+ii][4]*incrementer<=ScanParams[7*i+ii][3]-ScanParams[7*i+ii][2])
						Elseif(LoadedWave[i][0]==2||LoadedWave[i][0]==3)//||LoadedWave
							ii=1
							Do 
								If (ScanParams[7*i+ii][5]==ScanCount+1)
									Break
								Endif
								ii+=1
							While (ii<7)
							Do
								If (ii==1)
									SendtoFPGA(DefineValues(i,ii,incrementer),GrabDDSValues(-1,-1,-1),GrabMagiQValues(-1,-1,-1),i+ii/10,incrementer)//step number, substep, increment number//tells function to grab the setpoints for the DDS//sends to FPGA
									//	Print("Sent to SendtoFPGA: ")
									//	TestPrintVALS(DefineValues(i,ii,incrementer))
									//TestPrintDDS(GrabDDSValues(-1,-1,-1))						
								Elseif(ii<5)
							
									SendtoFPGA(DefineValues(-1,-1,-1),GrabDDSValues(i,ii,incrementer),GrabMagiQValues(-1,-1,-1),i+ii/10,incrementer)//Tells function to grab setpoints//step number, substep, imcrement number
								Else
									SendtoFPGA(DefineValues(-1,-1,-1),GrabDDSValues(-1,-1,-1),GrabMagiQValues(i,ii,incrementer),i+ii/10,incrementer)//Tells function to grab setpoints//step number, substep, imcrement number
								Endif
								incrementer+=1
							While (ScanParams[7*i+ii][4]*incrementer<=ScanParams[7*i+ii][3]-ScanParams[7*i+ii][2])
						Else
							Do
								SendtoFPGA(DefineValues(i,0,incrementer),GrabDDSValues(-1,-1,-1),GrabMagiQValues(-1,-1,-1),i+ii/10,incrementer)
								incrementer+=1
							While (ScanParams[7*i][4]*incrementer<ScanParams[7*i][3]-ScanParams[7*i][2])
						Endif
						Break
					Endif
				Endfor
				ScanCount+=1
			While (ScanCount<FindTotalScan())
		Else
			SendtoFPGA(DefineValues(-1,-1,-1),GrabDDSValues(-1,-1,-1),GrabMagiQValues(-1,-1,-1),i+ii/10,incrementer)
		Endif
		wat+=1
	While(	wat<outerloop)


End

//_____________________________________________________________________________
//
//	DefineValues(step,substep,increment)
//_____________________________________________________________________________
//
Function/WAVE DefineValues(step,substep,increment)
	Variable step,substep,increment
	setDatafolder root:ExpParams
	WAVE LoadedWave
	WAVE ScanParams
	MAKE/O/N=(FindTotalStep(),2) ReturnWaveVALS
	Variable i=0
	If (step>-1)
		Do
			ReturnWaveVALS[i][0]=LoadedWave[i][0]
			If (step==i)				
				ReturnWaveVALS[i][1]=increment*ScanParams[7*step+substep][4]+ScanParams[7*step+substep][2]
			Else
				If (LoadedWave[i][0]==1||LoadedWave[i][0]==2||LoadedWave[i][0]==3||LoadedWave[i][0]==7||LoadedWave[i][0]==8)
					ReturnWaveVALS[i][1]=ScanParams[7*i+1][1]
				Else
					ReturnWaveVALS[i][1]=ScanParams[7*i][1]
				Endif
			Endif
			i+=1
		While (i<FindTotalStep())
	Else
		Do
			ReturnWaveVALS[i][0]=LoadedWave[i][0]
			If (LoadedWave[i][0]==1||LoadedWave[i][0]==2||LoadedWave[i][0]==3||LoadedWave[i][0]==7||LoadedWave[i][0]==8)
				ReturnWaveVALS[i][1]=ScanParams[7*i+1][1]
			Else
				ReturnWaveVALS[i][1]=ScanParams[7*i][1]
			Endif
			i+=1
		While (i<FindTotalStep())
	Endif
	Return ReturnWaveVALS

End


//_____________________________________________________________________________
//
//	GrabDDSValues(step,substep,increment)
//_____________________________________________________________________________
//
Function/WAVE GrabDDSValues(step,substep,increment)
	Variable step,substep,increment
	SetDataFolder root:ExpParams
	WAVE LoadedWave
	WAVE ScanParams
	WAVE DDSSetPoints
	MAKE/O/N=(3,4) ReturnWave
	NVAR STATE_DET_FREQ,STATE_DET_AMP,STATE_DET_PHASE
	NVAR FLR_DET_FREQ,FLR_DET_AMP,FLR_DET_PHASE
	NVAR COOL_FREQ,COOL_AMP,COOL_PHASE
	Variable i=1
	Variable ii=2
	Variable/G DDS1Count=0
	Variable/G DDS2Count=0
	Variable/G DDS3Count=0
	Variable/G DDS7Count=0
	Variable/G DDS8Count=0
	Variable/G hold
	String DDSCounter,DDSCountwriter
	
	
	If (step>-1)
		Do
			ReturnWave[i-1][0]=i
			If (step==FindDDSLocation(i))
				DDSCounter= "DDS"+num2str(i)+"Count+=1"
				Execute DDSCounter
				For (ii=2;ii<5;ii+=1)
					If (substep==ii)
						If (ii==2)
							ReturnWave[i-1][1]=ScanParams[7*FindDDSLocation(i)+2][4]*increment+ScanParams[7*FindDDSLocation(i)+2][2]
							ReturnWave[i-1][3]=ScanParams[7*FindDDSLocation(i)+3][1]
							ReturnWave[i-1][2]=ScanParams[7*FindDDSLocation(i)+4][1]
						Elseif (ii==3)
							ReturnWave[i-1][1]=ScanParams[7*FindDDSLocation(i)+2][1]
							ReturnWave[i-1][3]=ScanParams[7*FindDDSLocation(i)+3][4]*increment+ScanParams[7*FindDDSLocation(i)+3][2]
							ReturnWave[i-1][2]=ScanParams[7*FindDDSLocation(i)+4][1]
						Elseif (ii==4)
							ReturnWave[i-1][1]=ScanParams[7*FindDDSLocation(i)+2][1]
							ReturnWave[i-1][3]=ScanParams[7*FindDDSLocation(i)+3][1]
							ReturnWave[i-1][2]=ScanParams[7*FindDDSLocation(i)+4][4]*increment+ScanParams[7*FindDDSLocation(i)+4][2]
						Endif
					Endif
				EndFor
				Break
			Endif
			i+=1
		While(i<=3)
		i=1
		Do
			DDSCountwriter= "hold=DDS"+num2str(i)+"Count"
			Execute DDSCountwriter
			If (hold==0&&FindDDSLocation(i)>-1)
				ReturnWave[i-1][1]=ScanParams[7*FindDDSLocation(i)+2][1]
				ReturnWave[i-1][2]=ScanParams[7*FindDDSLocation(i)+4][1]
				ReturnWave[i-1][3]=ScanParams[7*FindDDSLocation(i)+3][1]
			Elseif (hold==0&&FindDDSLocation(i)<0)
				For (ii=0;ii<3;ii+=1)
					ReturnWave[i-1][ii+1]=DDSSetPoints[i-1][ii]
				Endfor
			Endif
			i+=1
		While (i<=3)
				
	Else
		i=1
		Do
			ReturnWave[i-1][0]=i
			If (FindDDSLocation(i)>-1)
				ReturnWave[i-1][1]=ScanParams[7*FindDDSLocation(i)+2][1]
				ReturnWave[i-1][2]=ScanParams[7*FindDDSLocation(i)+4][1]
				ReturnWave[i-1][3]=ScanParams[7*FindDDSLocation(i)+3][1]
			Elseif (FindDDSLocation(i)<0)
			
				For (ii=0;ii<3;ii+=1)
					ReturnWave[i-1][ii+1]=DDSSetPoints[ii][i-1]
				Endfor
			Endif
			i+=1
		While (i<=3)
	Endif
	Return ReturnWave
End


//_____________________________________________________________________________
//
//Probably doesn't do anything to EO3
//Returns (EO num, Freq, Amp)
//_____________________________________________________________________________
//
Function/WAVE GrabMagiQValues(step,substep,increment)
	Variable step,substep,increment
	SetDataFolder root:ExpParams
	WAVE LoadedWave
	WAVE ScanParams
	WAVE EOSetPoints
	MAKE/O/N=(3,3) EOReturnWave
	NVAR STATE_DET_FREQ,STATE_DET_AMP,STATE_DET_PHASE
	NVAR FLR_DET_FREQ,FLR_DET_AMP,FLR_DET_PHASE
	NVAR COOL_FREQ,COOL_AMP,COOL_PHASE
	Variable i=2
	Variable ii=5
	Variable/G EO1Count=0
	Variable/G EO2Count=0
	Variable/G hold
	String DDSCounter,DDSCountwriter
	
	If (step>-1)
		Do
			If(LoadedWave[step][0]!=10)
				EOReturnWave[i-2][0]=i-2
			Else
				EOReturnWave[i-2][0]=2
			Endif
			If (step==FindEOLocation(i-1))
				DDSCounter= "EO"+num2str(i-1)+"Count+=1"
				Execute DDSCounter
				If (substep==5)
					EOReturnWave[i-2][1]=ScanParams[7*FindEOLocation(i-1)+5][4]*increment+ScanParams[7*FindEOLocation(i-1)+5][2]
					EOReturnWave[i-2][2]=ScanParams[7*FindEOLocation(i-1)+6][1]
				Elseif (substep==6)
					EOReturnWave[i-2][1]=ScanParams[7*FindEOLocation(i-1)+5][1]
					EOReturnWave[i-2][2]=ScanParams[7*FindEOLocation(i-1)+6][4]*increment+ScanParams[7*FindEOLocation(i-1)+6][2]
				Endif
				Break
			Endif
			i+=1
		While(i<=3)
		i=2
		Do
			DDSCountwriter= "hold=EO"+num2str(i-1)+"Count"
			Execute DDSCountwriter
			If (hold==0&&FindEOLocation(i-1)>-1)
				EOReturnWave[i-2][1]=ScanParams[7*FindEOLocation(i-1)+5][1]
				EOReturnWave[i-2][2]=ScanParams[7*FindEOLocation(i-1)+6][1]

			Elseif (hold==0&&FindEOLocation(i-1)<0)
				For (ii=0;ii<3;ii+=1)
					EOReturnWave[i-1][ii+1]=EOSetPoints[i-1][ii]
				Endfor
			Endif
			i+=1
		While (i<=3)
				
	Else
		i=2
		Do
			EOReturnWave[i-2][0]=i-1
			If (FindEOLocation(i-1)>-1)
				EOReturnWave[i-2][1]=ScanParams[7*FindEOLocation(i-1)+5][1]
				EOReturnWave[i-2][2]=ScanParams[7*FindEOLocation(i-1)+6][1]
			Elseif (FindEOLocation(i)<0)
				For (ii=0;ii<2;ii+=1)
					EOReturnWave[i-2][ii+1]=EOSetPoints[ii][i-2]
				Endfor
			Endif
			i+=1
		While (i<=3)
	Endif
	Return EOReturnWave
End


//_____________________________________________________________________________
//
//	EO1 is State Detection , EO2 is Flourescence Detection
//_____________________________________________________________________________
//
Function FindEOLocation(EOnum)
	Variable EOnum
	SetDataFolder root:ExpParams
	WAVE LoadedWave
	Variable i=0
	
	Do
		If(LoadedWave[i][0]==EOnum+1)
			Break
		Endif
		i+=1
	While (i<=FindTotalStep())
	
	If (i>=FindTotalStep())
		i=-1
	Endif
	
	Return i

End


//_____________________________________________________________________________
//
//	FindDDSLocation(DDSnum)
//_____________________________________________________________________________
//
Function FindDDSLocation(DDSnum)
	Variable DDSnum
	SetDataFolder root:ExpParams
	WAVE LoadedWave
	Variable i=0
	
	Do
		If(LoadedWave[i][0]==DDSnum)
			Break
		Endif
		i+=1
	While (i<=FindTotalStep())
	
	If (i>=FindTotalStep())
		i=-1
	Endif
	
	Return i

End


//_____________________________________________________________________________
//
//	SendtoFPGA(valuewave,ddsvaluewave,eovaluewave,scanner,incrementer)
//_____________________________________________________________________________
//
Function/WAVE SendtoFPGA(valuewave,ddsvaluewave,eovaluewave,scanner,incrementer)
	Variable scanner,incrementer
	WAVE valuewave
	WAVE ddsvaluewave
	WAVE eovaluewave
	SetDataFolder root:ExpParams
	WAVE LoadedWave
	WAVE NameWave
	Make/O/N=(NumberofStepstoSend(),2) WavetoFPGA=0
	Variable groupcount=1
	Variable multipliercount=0
	Variable elementcount=0
	Variable PreviousElementNumber=0
	Variable PreviousElementnumberScaled=0
	Variable i=0
	Variable loopmultiplier=0
	NVAR SendCounter
	NVAR Mask
	SVAR loadingscreen
	WAVE EO_INFO
	WAVE DDS_INFO
	String MagiQSet

	Do
		multipliercount=0
		Do
			//	Print("Group size: "+num2str(FindGroupSize(groupcount)))
			elementcount=0
			//Print("Prev: "+num2str(PreviousElementNumber))
			Do
				WavetoFPGA[elementcount+FindGroupSize(groupcount)*multipliercount+PreviousElementNumberScaled][0]=NameWave[valuewave[elementcount+PreviousElementNumber][0]]|Mask
				WavetoFPGA[elementcount+FindGroupSize(groupcount)*multipliercount+PreviousElementNumberScaled][1]=50*valuewave[elementcount+PreviousElementNumber][1]
				//	Print("("+num2str(elementcount)+","+num2str(FindGroupSize(groupcount)*multipliercount)+","+num2str(PreviousElementNumberScaled)+") by ("+num2str(elementcount)+","+num2str(PreviousElementnumber)+")")
				elementcount+=1
	
			While	(elementcount<FindGroupSize(groupcount))
	
			multipliercount+=1
		While (multipliercount<LoadedWave[groupcount-1][2])
		PreviousElementNumber+=FindGroupSize(groupcount)
		PreviousElementNumberscaled+=FindGroupSize(groupcount)*LoadedWave[groupcount-1][2]
		groupcount+=1
	While	(groupcount<=TotalGroupNumber())
		
	//*** This is for running the AO and EO frequencies
	i=0
	Do
		//Print(DDS_Info[i][3])
		If(DDS_INFO[i][3]==0)		
			SetDDS(i+1,ddsvaluewave[i][0],ddsvaluewave[i][1],ddsvaluewave[i][2])
		Endif
	
		//If(EO_INFO[i][3]==0)				
		//		MagiQset="MMCSet/O=1/F="+num2str(eovaluewave[i][1])+"/P="+num2str(eovaluewave[i][2])+" "+num2str(eovaluewave[i][0])
		//Execute MagiQset
		//Print MagiQset
		//Endif
		i+=1
	While(i<3)
		
		
	//	*** This is for Printing a running message
	//	If(SendCounter==0)
	//		Print("Sending to FPGA....")
	//		LoadingScreen="..."
	//	Else
	//		For(i=0;i<SendCounter;i+=1)
	//		LoadingScreen+="..."
	//		Print(LoadingScreen)
	//		EndFor
	//	Endif
	//	
	//	SendCounter=mod(SendCounter+1,5)

		
	SendSequence(WavetoFPGA)
			
			
	//******* How to take data from PMT	plugged into DI_01
		
		
	//recmask is the DI channel we take data on
	NVAR TDC=root:ExpParams:TDC
	runSequence(GetDataPointLoop(),recmask=DI_01,tdc=TDC)
	//AddtoData(runSequence(GetDataPointLoop(),recmask=DI_01),valuewave,ddsvaluewave,eovaluewave,scanner,incrementer)

		
	//******Alternatively, can use a do function to take data after each run:
	//	i=0
	//	Do
	//		runSequence(1)
	//		TakeData()
	//		i+=1
	//	While (i<loopmultiplier)
	//40 us between scans

	//print ddsvaluewave
	//print	eovaluewave
End


Function TestPrintEO(EOwave)
	WAVE EOwave
	Variable i=0
	
	Do
		Print("EO# : "+num2str(EOwave[i][0]))
		Print("Freq: "+num2str(EOwave[i][1]))
		Print("Amp: "+num2str(EOwave[i][2]))
		i+=1
	While (i<2)
	
End

Function TestPrintFinal(goodbyewave)
	WAVE goodbyewave
	Variable i=0
	
	Do
		Print("Name: "+num2str(goodbyewave[i][0]))
		Print("Time: "+num2str(goodbyewave[i][1]))
		i+=1
	While (i<NumberofStepstoSend())
	
End

Function TestPrintLoaded (load)
	WAVE Load
	Variable i=0

	Print("Names:")	
	Do
		Print(Load[i][0])
		i+=1
	While(i<FindTotalStep())
	
	i=0
	Print("Group Numbers:")
	Do
		Print(Load[i][1])
		i+=1
	While(i<FindtotalStep())
	
	i=0
	Print("Loop Numbers:")
	Do
		Print(Load[i][2])
		i+=1
	While(i<TotalGroupNumber())
End


Function TestTTL(ttlnumber)
	Variable ttlnumber
	
	Make/D/O/N=(1,2) turnon
	
	String turnttlon = "turnon={{TTL_0"+num2str(ttlnumber)+"},{0x1000000}}"
	Execute turnttlon
	
	sendSequence(turnon)
	runSequence(1)
	
End

//_____________________________________________________________________________
//
//	StopTTL() sets all sequencer output TTLs to zero
//_____________________________________________________________________________
//
Function StopTTL()
	Variable ttlnumber
	
	Make/D/O/N=(1,2) turnoff
	
	String turnttloff = "turnoff={{0x000000},{0x1000000}}"
	Execute turnttloff
	
	sendSequence(turnoff)
	runSequence(1)
	
End

//_____________________________________________________________________________
//
//	FindMaxInc()
//_____________________________________________________________________________
//
Function FindMaxInc()
	SetDatafolder root:ExpParams
	WAVE ScanParams
	Variable MAXINC
	Variable	i=0
	Variable ii=0
	
	For(i=0;i<FindTotalStep();i+=1)
		For(ii=0;ii<7;ii+=1)
			If(ScanParams[7*i+ii][4]!=0)
				If(MaxINC<(ScanParams[7*i+ii][3]-ScanParams[7*i+ii][2])/ScanParams[7*i+ii][4])
					MAXINC=(ScanParams[7*i+ii][3]-ScanParams[7*i+ii][2])/ScanParams[7*i+ii][4]
				Endif
			Endif
		EndFor
	EndFor

	Return MAXINC
end

//_____________________________________________________________________________
//
// GetDataPointLoop()
//_____________________________________________________________________________
//
Function GetDataPointLoop()
	ControlInfo Loops	
	Return V_Value
End

//_____________________________________________________________________________
//
// GetExperimentalLoop()
//_____________________________________________________________________________
//
Function GetExperimentalLoop()
	ControlInfo Times
	Return V_Value	
End

//_____________________________________________________________________________
//
// FindDataTakeNumber(in)
//_____________________________________________________________________________
//
Function FindDataTakeNumber(in)
	WAVE in
	SetDatafolder root:ExpParams
	WAVE NameWave
	Variable i=0
	Variable Datacount=0
	
	For(i=0;i<FindTotalStep();i+=1)
		If(gb_seq(NameWave[in[i][0]],3))
			Datacount+=1
		Endif
	EndFor
	
	Return datacount
End

//_____________________________________________________________________________
//
//This only works for data collection on 1 pmt also it probably does not work well for more than 1 data collection stage per experiment
//I think this will write both data collection stages onto the same wave, so if you can figure out how to tell where they split
//you can probably save them into different files and then write a program to compare them or whatever
//
//sequencerData[i][0][0][0] is the set of step numbers which are being incremented for a collection of data - you can find the name or ttl 
//by referencing the valwave which contains the sequence sent to the fpga at a given time
//these are given by step+substep/10 where substep refers to time, time(eo/ao), frequency,amplitude,phase, eo frequency,eo amplitude
//sequencerData[i][1][0][1] is the increment you are at for the ith set of data
//SequencerData[i][j][k][0] is the list of values sent to the FPGA, DDS, and MagiQ cards for the ith step
// 1<j<steps+1 is the value wave
// steps+1<j<steps+1+ddsnum is the dds wave
// steps+ddsnum<j is the eo wave
//Sequencerdata[i][0][0][j] is the set of data collected for the ith step
//_____________________________________________________________________________
//
Function OrganizeData(dat,val,dds,eo,scanner,incrementer,tosave)
	Wave dat,val,dds,eo
	Variable scanner,incrementer,tosave
	setDatafolder root:Expparams
	WAVE sequencerData
	NVAR DDSnum,EOnum
	String Makepath,Savedatastring
	WAVE/T TTLNAMES
	WAVE/T LoadWaveFiles
	
	Variable i=1
	Variable ii=0
	Variable stps
	Variable place=FindNextinData()
	sequencerData[place][0][0][0]=Scanner
	sequencerData[place][1][0][1]=incrementer
	For(i=1;i<stps+ddsnum+eonum+1;i+=1)
		If(i<stps+1)
			sequencerData[place][i][0][0]=val[i-1][0]
			sequencerData[place][i][1][0]=val[i-1][1]
		Elseif(i<stps+1+ddsNum&&i>stps)
			For(ii=0;ii<4;ii+=1)
				sequencerData[place][i][ii][0]=dds[i-1-stps][ii]
			EndFor
		Else
			For(ii=0;ii<3;ii+=1)
				sequencerData[place][i][ii][0]=eo[i-1-stps-ddsnum][ii]
			EndFor
		Endif
	Endfor
	For(i=1;i<GetDatapointloop()*FindDataTakeNumber(val)+1;i+=1)
		sequencerData[place][0][0][i]=dat[i-1]
	Endfor
	If(tosave)
		ControlInfo Sequences
		// Get settings path name and convert it to a string
		PathInfo DataPath
		String DataPathStr = S_path
		// Make sure a folder delimiter is at the end
		DataPathStr = ParseFilePath(2, DataPathStr, ":", 0, 0)
		NewPath/C/O/Q DataPath, DataPathStr+date()+"\""
		i=0
		Do
			if(StringMatch(IndexedFile(DataPath,-1,".dat"),"*"+S_VALUE+"_"+date()+"_"+num2str(i)+"*"))
				i+=1
			Else
				Break
			Endif

		While(1)
	
		Savedatastring="Save/P=DataPath/O/G/W sequencerData as \""+S_VALUE+"_"+date()+"_"+num2str(i)+".dat\""
		Execute Savedatastring
	Endif
	
End

//_____________________________________________________________________________
//
// FindNextinData()
//_____________________________________________________________________________
//
Function FindNextinData()
	setDatafolder root:Expparams
	WAVE sequencerData
	Variable i=0
	variable loc=0
	
	For(i=0;i<FindMaxInc()*FindTotalScan()*GetExperimentalLoop();i+=1)
		If(sequencerData[i][0][0][0])
			loc+=1
		Endif
	EndFor
	
	Return loc
End


//_____________________________________________________________________________
//
//	OLD VERSION
//	GenerateBounds2(load, settingwave) creates the ExOp parameter and scan controls
//_____________________________________________________________________________
//
Function GenerateBounds2(load,settingwave)
	WAVE load
	WAVE Settingwave
	SetDataFolder root:ExpParams
	NVAR VerticalButtonPosition
	NVAR COOL_FREQ
	NVAR COOL_AMP
	NVAR COOL_PHASE
	NVAR STATE_DET_FREQ
	NVAR STATE_DET_AMP
	NVAR STATE_DET_PHASE
	NVAR FLR_DET_FREQ
	NVAR FLR_DET_AMP
	NVAR FLR_DET_PHASE
	NVAR TotalStep
	NVAR TotalScan
	Variable i
	Variable/G value0
	Variable/G value1
	Variable/G value2
	Variable/G value3,value4,value5
	Variable/G value
	Variable ScanOrder=1
	Make/O/N=(5120,6) ScanParams=0
	NVAR DDS1Counter,DDS2Counter,DDS3Counter,DDSCounted,DDS7Counter,DDS8Counter,DDS10Counter
	String getscan0, count, counting
	String getscan1
	String getscan2
	String getscan3
	String getscan4
	String getscan5
	String generatelowlim0
	String generatelowlim1
	String generatelowlim2
	String generatelowlim3
	String generatelowlim4
	String generatelowlim5
	String generateupperlim0
	String generateupperlim1
	String generateupperlim2
	String generateupperlim3
	String generateupperlim4
	String generateupperlim5
	String generateInc0
	String generateInc1
	String generateInc2
	String generateInc3
	String generateInc4
	String generateInc5
	String generateScanOrder0
	String generateScanOrder1
	String generateScanOrder2
	String generateScanOrder3
	String generateScanOrder4
	String generateScanOrder5
	String generatesetpoint0
	String generatesetpoint1
	String generatesetpoint2
	String generatesetpoint3
	String generatesetpoint4
	String generatesetpoint5,setposition
				
	
	DDS1Counter=0
	DDS2Counter=0
	DDS3Counter=0
	DDSCounted=0
	DDS7Counter=0
	DDS8Counter=0
	DDS10Counter=0
	

	TotalScan=0
	For (i=0;i<TotalStep;i+=1)
		setposition="ControlInfo Step"+num2str(i+1)+"Title; verticalButtonposition=V_top"
		Execute setposition
		value0=0
		value1=0
		value2=0
		value3=0
		value4=0
		value5=0
		If (load[i][0]==1||load[i][0]==7||load[i][0]==8)
				
				
			getscan0 = "ControlInfo Step"+num2str(i+1)+"Scan0;value0=V_Value"
			getscan1 = "ControlInfo Step"+num2str(i+1)+"Scan1;value1=V_Value"
			getscan2 = "ControlInfo Step"+num2str(i+1)+"Scan2;value2=V_Value"
			getscan3 = "ControlInfo Step"+num2str(i+1)+"Scan3;value3=V_Value"
			Execute getscan0
			Execute getscan1
			Execute getscan2
			Execute getscan3
				

			generatelowlim0 = "SetVariable Step"+num2str(i+1)+"lowerlim0, pos={540, VerticalButtonPosition}, title=\"Start Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][2])
			generatelowlim1 = "SetVariable Step"+num2str(i+1)+"lowerlim1, pos={540, VerticalButtonPosition+20}, title=\"Start Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+2][2])
			generatelowlim2 = "SetVariable Step"+num2str(i+1)+"lowerlim2, pos={540, VerticalButtonPosition+40}, title=\"Start Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+3][2])+",limits={0,1023,1}"
			generatelowlim3 = "SetVariable Step"+num2str(i+1)+"lowerlim3, pos={540, VerticalButtonPosition+60}, title=\"Start Phase\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+4][2])
			generateupperlim0 = "SetVariable Step"+num2str(i+1)+"upperlim0, pos={740, VerticalButtonPosition}, title=\"End Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][3])
			generateupperlim1 = "SetVariable Step"+num2str(i+1)+"upperlim1, pos={740, VerticalButtonPosition+20}, title=\"End Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+2][3])
			generateupperlim2 = "SetVariable Step"+num2str(i+1)+"upperlim2, pos={740, VerticalButtonPosition+40}, title=\"End Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+3][3])+",limits={0,1023,1}"
			generateupperlim3 = "SetVariable Step"+num2str(i+1)+"upperlim3, pos={740, VerticalButtonPosition+60}, title=\"End Phase\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+4][3])
			generateInc0 = "SetVariable Step"+num2str(i+1)+"Inc0, pos={940, VerticalButtonPosition}, title=\"Increment (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][4])
			generateInc1 = "SetVariable Step"+num2str(i+1)+"Inc1, pos={940, VerticalButtonPosition+20}, title=\"Increment (MHZ)\", win=Pulse,size={130,20},bodywidth=50,limits={0.001,400,.001},value=_NUM:"+num2str(SettingWave[7*i+2][4])
			generateInc2 = "SetVariable Step"+num2str(i+1)+"Inc2, pos={940, VerticalButtonPosition+40}, title=\"Increment\", win=Pulse,size={130,20},bodywidth=50,limits={1,1023,1},value=_NUM:"+num2str(SettingWave[7*i+3][4])
			generateInc3 = "SetVariable Step"+num2str(i+1)+"Inc3, pos={940, VerticalButtonPosition+60}, title=\"Increment (Degrees)\", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=_NUM:"+num2str(SettingWave[7*i+4][4])
			generateScanOrder0 = "SetVariable Step"+num2str(i+1)+"ScanOrder0, pos={1080, VerticalButtonPosition}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
			generateScanOrder1 = "SetVariable Step"+num2str(i+1)+"ScanOrder1, pos={1080, VerticalButtonPosition+20}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
			generateScanOrder2 = "SetVariable Step"+num2str(i+1)+"ScanOrder2, pos={1080, VerticalButtonPosition+40}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
			generateScanOrder3 = "SetVariable Step"+num2str(i+1)+"ScanOrder3, pos={1080, VerticalButtonPosition+60}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
				
			generatesetpoint0 = "SetVariable Step"+num2str(i+1)+"setpoint0, pos={340, VerticalButtonPosition}, title=\"Time Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][1])
			generatesetpoint1 = "SetVariable Step"+num2str(i+1)+"setpoint1, pos={340, VerticalButtonPosition+20}, title=\"Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+2][1])
			generatesetpoint2 = "SetVariable Step"+num2str(i+1)+"setpoint2, pos={340, VerticalButtonPosition+40}, title=\"Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+3][1])
			generatesetpoint3 = "SetVariable Step"+num2str(i+1)+"setpoint3, pos={340, VerticalButtonPosition+60}, title=\"Phase\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+4][1])
				
			count = "DDSCounted=DDS"+num2str(load[i][0])+"Counter"
			Execute count
			If (DDSCounted==0)
				Execute generatesetpoint0
				Execute generatesetpoint1
				Execute generatesetpoint2
				Execute generatesetpoint3
				counting = "DDS"+num2str(load[i][0])+"Counter+=1"
				Execute counting
					
				If (value0==1)
					Execute generatelowlim0
					Execute generateupperlim0
					Execute generateInc0
					If (SettingWave[7*i+1][5]==0)
						Execute generateScanOrder0+num2str(ScanOrder)
					Else
						Execute generateScanOrder0+num2str(SettingWave[7*i+1][5])
					Endif
					ScanOrder+=1
					TotalScan+=1
					ScanParams[7*i+1][0]=1
						
				endif
					
				IF (value1==1)
					Execute generatelowlim1
					Execute generateupperlim1
					Execute generateInc1
					If (SettingWave[7*i+2][5]==0)
						Execute generateScanOrder1+num2str(ScanOrder)
					Else
						Execute generateScanOrder1+num2str(SettingWave[7*i+2][5])
					Endif
					ScanOrder+=1
					TotalScan+=1
					ScanParams[7*i+2][0]=1
	
				Endif
				If (value2==1)
					Execute generatelowlim2
					Execute generateupperlim2
					Execute generateInc2
					If (SettingWave[7*i+3][5]==0)
						Execute generateScanOrder2+num2str(ScanOrder)
					Else
						Execute generateScanOrder2+num2str(SettingWave[7*i+3][5])
					Endif
					ScanOrder+=1
					TotalScan+=1
					ScanParams[7*i+3][0]=1
						
				endif
				If (value3==1)
					Execute generatelowlim3
					Execute generateupperlim3
					Execute generateInc3
					If (SettingWave[7*i+4][5]==0)
						Execute generateScanOrder3+num2str(ScanOrder)
						ScanOrder+=1
					Else
						Execute generateScanOrder3+num2str(SettingWave[7*i+4][5])
					Endif
					TotalScan+=1
					ScanParams[7*i+4][0]=1
			
				Endif
				VerticalButtonPosition+=120
			Else
				Execute generatesetpoint0

				If (value0==1)
					Execute generatelowlim0
					Execute generateupperlim0
					Execute generateInc0
					If (SettingWave[7*i+1][5]==0)
						Execute generateScanOrder0+num2str(ScanOrder)
					Else
						Execute generateScanOrder0+num2str(SettingWave[7*i+1][5])
					Endif
					ScanOrder+=1
					TotalScan+=1
					ScanParams[7*i+1][0]=1
						
				endif
					
				VerticalButtonPosition+=30
			Endif
		Elseif(Load[i][0]==10)
			getscan0 = "ControlInfo Step"+num2str(i+1)+"Scan0;value0=V_Value"
			getscan4 = "ControlInfo Step"+num2str(i+1)+"Scan4;value4=V_Value"
			getscan5 = "ControlInfo Step"+num2str(i+1)+"Scan5;value5=V_Value"
			Execute getscan0
			Execute getscan4
			Execute getscan5

			generatelowlim0 = "SetVariable Step"+num2str(i+1)+"lowerlim0, pos={540, VerticalButtonPosition}, title=\"Start Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][2])
			generateupperlim0 = "SetVariable Step"+num2str(i+1)+"upperlim0, pos={740, VerticalButtonPosition}, title=\"End Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][3])
			generateInc0 = "SetVariable Step"+num2str(i+1)+"Inc0, pos={940, VerticalButtonPosition}, title=\"Increment (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][4])
			generateScanOrder0 = "SetVariable Step"+num2str(i+1)+"ScanOrder0, pos={1080, VerticalButtonPosition}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
			generatesetpoint0 = "SetVariable Step"+num2str(i+1)+"setpoint0, pos={340, VerticalButtonPosition}, title=\"Time Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][1])				
			generatelowlim4 = "SetVariable Step"+num2str(i+1)+"lowerlim4, pos={540, VerticalButtonPosition+20}, title=\"Start EO Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+5][2])
			generatelowlim5 = "SetVariable Step"+num2str(i+1)+"lowerlim5, pos={540, VerticalButtonPosition+40}, title=\"Start EO Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+6][2])
			generateupperlim4 = "SetVariable Step"+num2str(i+1)+"upperlim4, pos={740, VerticalButtonPosition+20}, title=\"End EO Frequency\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+5][3])
			generateupperlim5 = "SetVariable Step"+num2str(i+1)+"upperlim5, pos={740, VerticalButtonPosition+40}, title=\"End EO Amplitude (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+6][3])
			generateInc4 = "SetVariable Step"+num2str(i+1)+"Inc4, pos={940, VerticalButtonPosition+20}, title=\"Increment (MHZ)\", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=_NUM:"+num2str(SettingWave[7*i+5][4])
			generateInc5 = "SetVariable Step"+num2str(i+1)+"Inc5, pos={940, VerticalButtonPosition+40}, title=\"Increment\", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=_NUM:"+num2str(SettingWave[7*i+6][4])
			generateScanOrder4 = "SetVariable Step"+num2str(i+1)+"ScanOrder4, pos={1080, VerticalButtonPosition+20}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
			generateScanOrder5 = "SetVariable Step"+num2str(i+1)+"ScanOrder5, pos={1080, VerticalButtonPosition+40}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
			generatesetpoint4 = "SetVariable Step"+num2str(i+1)+"setpoint4, pos={340, VerticalButtonPosition+20}, title=\"EO Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+5][1])
			generatesetpoint5 = "SetVariable Step"+num2str(i+1)+"setpoint5, pos={340, VerticalButtonPosition+40}, title=\"EO Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+6][1])


			count = "DDSCounted=DDS"+num2str(load[i][0])+"Counter"
			Execute count
			If (DDSCounted==0)
				Execute generatesetpoint0
				Execute generatesetpoint4
				Execute generatesetpoint5
				counting = "DDS"+num2str(load[i][0])+"Counter+=1"
				Execute counting
				If (value0==1)
					Execute generatelowlim0
					Execute generateupperlim0
					Execute generateInc0
					If (SettingWave[7*i+1][5]==0)
						Execute generateScanOrder0+num2str(ScanOrder)
					Else
						Execute generateScanOrder0+num2str(SettingWave[7*i+1][5])
					Endif
					ScanOrder+=1
					TotalScan+=1
					ScanParams[7*i+1][0]=1
						
				endif
		
				If (value4==1)
					Execute generatelowlim4
					Execute generateupperlim4
					Execute generateInc4
					If (SettingWave[7*i+5][5]==0)
						Execute generateScanOrder4+num2str(ScanOrder)
						ScanOrder+=1
					Else
						Execute generateScanOrder4+num2str(SettingWave[7*i+5][5])
					Endif
					TotalScan+=1
					ScanParams[7*i+5][0]=1
			
				Endif
				If (value5==1)
					Execute generatelowlim5
					Execute generateupperlim5
					Execute generateInc5
					If (SettingWave[7*i+6][5]==0)
						Execute generateScanOrder5+num2str(ScanOrder)
						ScanOrder+=1
					Else
						Execute generateScanOrder5+num2str(SettingWave[7*i+6][5])
					Endif
					TotalScan+=1
					ScanParams[7*i+6][0]=1
			
				Endif
				VerticalButtonPosition+=60
			Endif
				
				
		Elseif(Load[i][0]==2||Load[i][0]==3)	
				
			getscan0 = "ControlInfo Step"+num2str(i+1)+"Scan0;value0=V_Value"
			getscan1 = "ControlInfo Step"+num2str(i+1)+"Scan1;value1=V_Value"
			getscan2 = "ControlInfo Step"+num2str(i+1)+"Scan2;value2=V_Value"
			getscan3 = "ControlInfo Step"+num2str(i+1)+"Scan3;value3=V_Value"
			getscan4 = "ControlInfo Step"+num2str(i+1)+"Scan4;value4=V_Value"
			getscan5 = "ControlInfo Step"+num2str(i+1)+"Scan5;value5=V_Value"
			Execute getscan0
			Execute getscan1
			Execute getscan2
			Execute getscan3
			Execute getscan4
			Execute getscan5
				

			generatelowlim0 = "SetVariable Step"+num2str(i+1)+"lowerlim0, pos={540, VerticalButtonPosition}, title=\"Start Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][2])
			generatelowlim1 = "SetVariable Step"+num2str(i+1)+"lowerlim1, pos={540, VerticalButtonPosition+20}, title=\"Start AO Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+2][2])
			generatelowlim2 = "SetVariable Step"+num2str(i+1)+"lowerlim2, pos={540, VerticalButtonPosition+40}, title=\"Start AO Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+3][2])+",limits={0,1023,1}"
			generatelowlim3 = "SetVariable Step"+num2str(i+1)+"lowerlim3, pos={540, VerticalButtonPosition+60}, title=\"Start AO Phase\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+4][2])
			generatelowlim4 = "SetVariable Step"+num2str(i+1)+"lowerlim4, pos={540, VerticalButtonPosition+80}, title=\"Start EO Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+5][2])
			generatelowlim5 = "SetVariable Step"+num2str(i+1)+"lowerlim5, pos={540, VerticalButtonPosition+100}, title=\"Start EO Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+6][2])
			generateupperlim0 = "SetVariable Step"+num2str(i+1)+"upperlim0, pos={740, VerticalButtonPosition}, title=\"End Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][3])
			generateupperlim1 = "SetVariable Step"+num2str(i+1)+"upperlim1, pos={740, VerticalButtonPosition+20}, title=\"End AO Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+2][3])
			generateupperlim2 = "SetVariable Step"+num2str(i+1)+"upperlim2, pos={740, VerticalButtonPosition+40}, title=\"End AO Amplitude (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+3][3])+",limits={0,1023,1}"
			generateupperlim3 = "SetVariable Step"+num2str(i+1)+"upperlim3, pos={740, VerticalButtonPosition+60}, title=\"End AO Phase\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+4][3])
			generateupperlim4 = "SetVariable Step"+num2str(i+1)+"upperlim4, pos={740, VerticalButtonPosition+80}, title=\"End EO Frequency\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+5][3])
			generateupperlim5 = "SetVariable Step"+num2str(i+1)+"upperlim5, pos={740, VerticalButtonPosition+100}, title=\"End EO Amplitude (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+6][3])
			generateInc0 = "SetVariable Step"+num2str(i+1)+"Inc0, pos={940, VerticalButtonPosition}, title=\"Increment (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][4])
			generateInc1 = "SetVariable Step"+num2str(i+1)+"Inc1, pos={940, VerticalButtonPosition+20}, title=\"Increment (MHZ)\", win=Pulse,size={130,20},bodywidth=50,limits={0.001,400,.001},value=_NUM:"+num2str(SettingWave[7*i+2][4])
			generateInc2 = "SetVariable Step"+num2str(i+1)+"Inc2, pos={940, VerticalButtonPosition+40}, title=\"Increment\", win=Pulse,size={130,20},bodywidth=50,limits={1,1023,1},value=_NUM:"+num2str(SettingWave[7*i+3][4])
			generateInc3 = "SetVariable Step"+num2str(i+1)+"Inc3, pos={940, VerticalButtonPosition+60}, title=\"Increment (Degrees)\", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=_NUM:"+num2str(SettingWave[7*i+4][4])
			generateInc4 = "SetVariable Step"+num2str(i+1)+"Inc4, pos={940, VerticalButtonPosition+80}, title=\"Increment (MHZ)\", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=_NUM:"+num2str(SettingWave[7*i+5][4])
			generateInc5 = "SetVariable Step"+num2str(i+1)+"Inc5, pos={940, VerticalButtonPosition+100}, title=\"Increment\", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=_NUM:"+num2str(SettingWave[7*i+6][4])
			generateScanOrder0 = "SetVariable Step"+num2str(i+1)+"ScanOrder0, pos={1080, VerticalButtonPosition}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
			generateScanOrder1 = "SetVariable Step"+num2str(i+1)+"ScanOrder1, pos={1080, VerticalButtonPosition+20}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
			generateScanOrder2 = "SetVariable Step"+num2str(i+1)+"ScanOrder2, pos={1080, VerticalButtonPosition+40}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
			generateScanOrder3 = "SetVariable Step"+num2str(i+1)+"ScanOrder3, pos={1080, VerticalButtonPosition+60}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
			generateScanOrder4 = "SetVariable Step"+num2str(i+1)+"ScanOrder4, pos={1080, VerticalButtonPosition+80}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
			generateScanOrder5 = "SetVariable Step"+num2str(i+1)+"ScanOrder5, pos={1080, VerticalButtonPosition+100}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
								
			generatesetpoint0 = "SetVariable Step"+num2str(i+1)+"setpoint0, pos={340, VerticalButtonPosition}, title=\"Time Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][1])
			generatesetpoint1 = "SetVariable Step"+num2str(i+1)+"setpoint1, pos={340, VerticalButtonPosition+20}, title=\"AO Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+2][1])
			generatesetpoint2 = "SetVariable Step"+num2str(i+1)+"setpoint2, pos={340, VerticalButtonPosition+40}, title=\"AO Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+3][1])
			generatesetpoint3 = "SetVariable Step"+num2str(i+1)+"setpoint3, pos={340, VerticalButtonPosition+60}, title=\"AO Phase\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+4][1])
			generatesetpoint4 = "SetVariable Step"+num2str(i+1)+"setpoint4, pos={340, VerticalButtonPosition+80}, title=\"EO Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+5][1])
			generatesetpoint5 = "SetVariable Step"+num2str(i+1)+"setpoint5, pos={340, VerticalButtonPosition+100}, title=\"EO Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+6][1])
				
				

				
			count = "DDSCounted=DDS"+num2str(load[i][0])+"Counter"
			Execute count
			If (DDSCounted==0)
				Execute generatesetpoint0
				Execute generatesetpoint1
				Execute generatesetpoint2
				Execute generatesetpoint3
				Execute generatesetpoint4
				Execute generatesetpoint5
				counting = "DDS"+num2str(load[i][0])+"Counter+=1"
				Execute counting
					
				If (value0==1)
					Execute generatelowlim0
					Execute generateupperlim0
					Execute generateInc0
					If (SettingWave[7*i+1][5]==0)
						Execute generateScanOrder0+num2str(ScanOrder)
					Else
						Execute generateScanOrder0+num2str(SettingWave[7*i+1][5])
					Endif
					ScanOrder+=1
					TotalScan+=1
					ScanParams[7*i+1][0]=1
						
				endif
					
				IF (value1==1)
					Execute generatelowlim1
					Execute generateupperlim1
					Execute generateInc1
					If (SettingWave[7*i+2][5]==0)
						Execute generateScanOrder1+num2str(ScanOrder)
					Else
						Execute generateScanOrder1+num2str(SettingWave[7*i+2][5])
					Endif
					ScanOrder+=1
					TotalScan+=1
					ScanParams[7*i+2][0]=1
	
				Endif
				If (value2==1)
					Execute generatelowlim2
					Execute generateupperlim2
					Execute generateInc2
					If (SettingWave[7*i+3][5]==0)
						Execute generateScanOrder2+num2str(ScanOrder)
					Else
						Execute generateScanOrder2+num2str(SettingWave[7*i+3][5])
					Endif
					ScanOrder+=1
					TotalScan+=1
					ScanParams[7*i+3][0]=1
						
				endif
				If (value3==1)
					Execute generatelowlim3
					Execute generateupperlim3
					Execute generateInc3
					If (SettingWave[7*i+4][5]==0)
						Execute generateScanOrder3+num2str(ScanOrder)
						ScanOrder+=1
					Else
						Execute generateScanOrder3+num2str(SettingWave[7*i+4][5])
					Endif
					TotalScan+=1
					ScanParams[7*i+4][0]=1
			
				Endif
				If (value4==1)
					Execute generatelowlim4
					Execute generateupperlim4
					Execute generateInc4
					If (SettingWave[7*i+5][5]==0)
						Execute generateScanOrder4+num2str(ScanOrder)
						ScanOrder+=1
					Else
						Execute generateScanOrder4+num2str(SettingWave[7*i+5][5])
					Endif
					TotalScan+=1
					ScanParams[7*i+5][0]=1
			
				Endif
				If (value5==1)
					Execute generatelowlim5
					Execute generateupperlim5
					Execute generateInc5
					If (SettingWave[7*i+6][5]==0)
						Execute generateScanOrder5+num2str(ScanOrder)
						ScanOrder+=1
					Else
						Execute generateScanOrder5+num2str(SettingWave[7*i+6][5])
					Endif
					TotalScan+=1
					ScanParams[7*i+6][0]=1
			
				Endif
				VerticalButtonPosition+=180
			Else
				Execute generatesetpoint0

				If (value0==1)
					Execute generatelowlim0
					Execute generateupperlim0
					Execute generateInc0
					If (SettingWave[7*i+1][5]==0)
						Execute generateScanOrder0+num2str(ScanOrder)
					Else
						Execute generateScanOrder0+num2str(SettingWave[7*i+1][5])
					Endif
					ScanOrder+=1
					TotalScan+=1
					ScanParams[7*i+1][0]=1
						
				endif
					
				VerticalButtonPosition+=30
			Endif
		Else
			String getscan = "ControlInfo Step"+num2str(i+1)+"Scan;value=V_Value"
			Execute getscan

			String generatelowlim = "SetVariable Step"+num2str(i+1)+"lowerlim, pos={540, VerticalButtonPosition}, title=\"Start Duration (us)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i][2])+",limits={.02,2000000,0.02}"
			String generateupperlim = "SetVariable Step"+num2str(i+1)+"upperlim, pos={740, VerticalButtonPosition}, title=\"End Duration(us)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i][3])+",limits={.02,2000000,0.02}"
			String generateInc = "SetVariable Step"+num2str(i+1)+"Inc, pos={940, VerticalButtonPosition}, title=\"Increment (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,20000,.02},value=_NUM:"+num2str(SettingWave[7*i][4])				
			String generatesetpoint = "SetVariable Step"+num2str(i+1)+"setpoint, pos={340, VerticalButtonPosition}, title=\"Time Duration (us)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i][1])+",limits={.02,2000000,0.002}"
			String generateScanOrder = "SetVariable Step"+num2str(i+1)+"ScanOrder, pos={1080, VerticalButtonPosition}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
				
			Execute generatesetpoint
				
			If (value==1)
				Execute generatelowlim
				Execute generateupperlim	
				Execute	generateInc
				If (SettingWave[7*i][5]==0)
					Execute generateScanOrder+num2str(ScanOrder)
				Else
					Execute generateScanOrder+num2str(SettingWave[7*i][5])
				Endif
				ScanOrder+=1
				TotalScan+=1
				ScanParams[7*i][0]=1
					
			endif
			VerticalButtonPosition+=30
		Endif
	EndFor
End