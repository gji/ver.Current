#pragma rtGlobals=1		// Use modern global access method.

//_____________________________________________________________________________
//_____________________________________________________________________________
//
//	This first Half of code is for the Pulse Creator panel which is used to create pulse 
//	sequences (without durations or frequency/amplitude/phase)
//_____________________________________________________________________________
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
	
	SetDataFolder root:Sequencer:Data
	wave PopupVals		=	root:ExpParams:popupvals

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
	NVAR VerticalButtonPosition
	
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
				MoveWindow/W=Pulse V_left,V_top,V_left+650,(125+V_top+VerticalButtonPosition+20)*72/ScreenResolution
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
			SetVariable $("Step"+num2str(ExOpIdx)+"SBCNumModes"), pos={140, VerticalButtonPosition+2}, title="Modes", win=Pulse,size={100,20},bodywidth=30,limits={1,20,1},value=_NUM:0, proc=GenerateSBCoolingControls
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
				if(stringmatch(ControlParamName,"DC")==0)
					DefaultVal = str2num(ExOpElement(expt.ExOps[ExOpIdx].Values, k))
					SetVariable $("Step"+num2str(ExOpIdx)+"setpoint"+num2str(k)),format="%.4f", pos={340, VerticalButtonPosition+2}, title=ControlParamName, win=Pulse,size={130,20},bodywidth=70,limits={minVal,maxVal,minInc},value=_NUM:DefaultVal
				endif
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
			SetVariable $("Step"+num2str(ExOpIdx)+"SBCNumModes"), pos={140, VerticalButtonPosition+2}, title="Modes", win=Pulse,size={100,20},bodywidth=30,limits={1,20,1},value=_NUM:0, proc=GenerateSBCoolingControls
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
					SetVariable $("Step"+num2str(ExOpIdx)+"Scan"+num2str(k)+"Min"), pos={170+300, VerticalButtonPosition}, title="Min",format="%.4f", win=Pulse,size={130,20},bodywidth=70,limits={minVal,maxVal,minInc},value=_NUM:scanStart
					SetVariable $("Step"+num2str(ExOpIdx)+"Scan"+num2str(k)+"Max"), pos={170+400, VerticalButtonPosition}, title="Max",format="%.4f", win=Pulse,size={130,20},bodywidth=70,limits={minVal,maxVal,minInc},value=_NUM:scanStop
					SetVariable $("Step"+num2str(ExOpIdx)+"Scan"+num2str(k)+"Inc"), pos={170+500, VerticalButtonPosition}, title="Inc",format="%.4f", win=Pulse,size={130,20},bodywidth=70,limits={minInc,maxVal,minInc},value=_NUM:scanInc

				endif
				if ( str2num(ExOpElement(expt.ExOps[ExOpIdx].ScannableParameters, k)) == 0 )
					CheckBox $("Step"+num2str(ExOpIdx)+"Scan"+num2str(k)), disable=2
				endif
				DefaultVal = str2num(ExOpElement(expt.ExOps[ExOpIdx].Values, k))
				SetVariable $("Step"+num2str(ExOpIdx)+"setpoint"+num2str(k)), pos={340, VerticalButtonPosition+2}, title=ControlParamName,format="%.4f",win=Pulse,size={130,20},bodywidth=70,limits={minVal,maxVal,minInc},value=_NUM:DefaultVal
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
				SetVariable $("Step"+(numStep)+"SBCoolingFreq"+num2str(k)), pos={370+150*k, VerticalButtonPosition+2},title="Freq "+num2str(k+1),format="%.4f", win=Pulse,size={130,20},bodywidth=70,limits={10,300,0.0005},value=_NUM:100
				SetVariable $("Step"+(numStep)+"SBCoolingTime"+num2str(k)), pos={370+150*k, VerticalButtonPosition+25},title="Duration "+num2str(k+1),format="%.4f", win=Pulse,size={130,20},bodywidth=70,limits={1,100000,1},value=_NUM:10
				SetVariable $("Step"+(numStep)+"SBCoolingAmplitude"+num2str(k)), pos={370+150*k, VerticalButtonPosition+50},title="Amp "+num2str(k+1),format="%.4f", win=Pulse,size={130,20},bodywidth=70,limits={1,2047,1},value=_NUM:2047
				SetVariable $("Step"+(numStep)+"SBCoolingCycles"+num2str(k)), pos={370+150*k, VerticalButtonPosition+75},title="Cycles "+num2str(k+1), win=Pulse,size={130,20},bodywidth=70,limits={1,500,1},value=_NUM:10
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
				if(stringmatch(ControlParamName,"DC")==0)
					for (ExOpIdx = 0; ExOpIdx < expt.numExOps; ExOpIdx +=1)
						if (cmpstr(expt.ExOps[ExOpIdx].name, ExOpName) == 0)
							elementIdx = WhichListItem(ControlParamName, expt.ExOps[ExOpIdx].ControlParameters)
							minVal = str2num(ExOpElement(expt.ExOps[ExOpIdx].MinVal, elementIdx))
							maxVal = str2num(ExOpElement(expt.ExOps[ExOpIdx].MaxVal, elementIdx))
							minInc = str2num(ExOpElement(expt.ExOps[ExOpIdx].MinInc, elementIdx))
							break
						endif
					endfor
					SetVariable $(cba.ctrlName+"Min"), pos={V_left+300, V_top}, title="Min",format="%.4f", win=Pulse,size={130,20},bodywidth=70,limits={minVal,maxVal,minInc},value=_NUM:minVal
					SetVariable $(cba.ctrlName+"Max"), pos={V_left+400, V_top}, title="Max",format="%.4f", win=Pulse,size={130,20},bodywidth=70,limits={minVal,maxVal,minInc},value=_NUM:maxVal
					SetVariable $(cba.ctrlName+"Inc"), pos={V_left+500, V_top}, title="Inc",format="%.4f", win=Pulse,size={130,20},bodywidth=70,limits={minInc,maxVal,minInc},value=_NUM:minInc
				else
					minVal	=0
					maxVal	=0
					minInc	=0
					
					SetVariable $(cba.ctrlName+"Min"), pos={V_left+300, V_top}, title="Min",format="%.4f", win=Pulse,size={130,20},bodywidth=70,limits={minVal,maxVal,minInc},value=_NUM:minVal
					SetVariable $(cba.ctrlName+"Max"), pos={V_left+400, V_top}, title="Max",format="%.4f", win=Pulse,size={130,20},bodywidth=70,limits={minVal,maxVal,minInc},value=_NUM:maxVal
					SetVariable $(cba.ctrlName+"Inc"), pos={V_left+500, V_top}, title="Inc",format="%.4f", win=Pulse,size={130,20},bodywidth=70,limits={minInc,maxVal,minInc},value=_NUM:minInc
				endif
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
//	Creates set scan, clear scan, and run buttons and the cycles #
//_____________________________________________________________________________
//
Function CreateButtons()
	SetDataFolder root:ExpParams
	NVAR VerticalButtonPosition
	
	SetVariable Loops pos={542,VerticalButtonPosition},win=Pulse,title="Data Point Loop", limits={0,65535,1}, size={150,20},value=_NUM:300
	SetVariable Times pos={700,VerticalButtonPosition},win=Pulse,title="Experimental Loop", limits={0,2^16,1}, size={150,20},value=_NUM:1
	
	VerticalButtonPosition+=30
	
	//Button LoadSettings win=Pulse, pos={15,VerticalButtonPosition}, title="Load Settings", proc=LoadSettingsProc ,size={100,20}
	Button SaveSettings win=Pulse, pos={15,VerticalButtonPosition}, title="Save Settings", proc=SaveSettingsProc, size={100,20}
	PopupMenu LoadSettings,pos={155,VerticalButtonPosition},size={202,21},bodyWidth=150,proc=LoadSettingsPopMenuProc,title="Load:",mode=1,value=LoadSettingsList()
	Button Scan win=Pulse,pos={575,VerticalButtonPosition}, title="Scan", proc=ScanProc,size={100,20}
	Button AlignmentSweep win=Pulse,pos={575,VerticalButtonPosition+30},size={145,22},proc=AlignScanProc,title="Alignment Sweeper"
	Button EndScan win=Pulse,pos={575,VerticalButtonPosition+60},size={145,22},proc=EndScanProc,title="End Scan"


End

Function PMTproc(ctrlName,checked): CheckBoxControl
	String ctrlName
	Variable checked
		
	Setdatafolder root:ExpParams
	
	
	NVAR PMT 
	PMT=TTL_00
	NVAR PMT_01
	NVAR PMT_02
	NVAR PMT_03
	NVAR PMT_04
	NVAR PMT_05
	NVAR PMT_06
	NVAR PMT_07
	NVAR PMT_08
	
	WAVE numIon 		= root:sequencer:alignmentsweeper:numionchanalign	
	
	strswitch(ctrlName)
		case "PMT1box":
			if(checked)
				PMT_01		= DI_01
				SetVariable NumIon1, disable=0
			else
				PMT_01		= TTL_00
				NumIon[0]=0
				SetVariable NumIon1, disable=2
			endif
			break
		case "PMT2box":
			if(checked)
				PMT_02		= DI_02
				SetVariable NumIon2, disable=0
			else
				PMT_02		= TTL_00
				NumIon[1]=0
				SetVariable NumIon2, disable=2
			endif
			break
		case "PMT3box":
			if(checked)
				PMT_03		= DI_03
				SetVariable NumIon3, disable=0				
			else
				PMT_03		= TTL_00
				NumIon[2]=0
				SetVariable NumIon3, disable=2
			endif
			break
		case "PMT4box":
			if(checked)
				PMT_04		= DI_04
				SetVariable NumIon4, disable=0				
			else
				PMT_04		= TTL_00
				NumIon[3]=0
				SetVariable NumIon4, disable=2			
			endif
			break	
		case "PMT5box":
			if(checked)
				PMT_05		= DI_05
				SetVariable NumIon5, disable=0				
			else
				PMT_05		= TTL_00
				NumIon[4]=0
				SetVariable NumIon5, disable=2	
			endif
			break
		case "PMT6box":
			if(checked)
				PMT_06		= DI_06
				SetVariable NumIon6, disable=0				
			else
				PMT_06		= TTL_00
				NumIon[5]=0
				SetVariable NumIon6, disable=2
			endif
			break
		case "PMT7box":
			if(checked)
				PMT_07		= DI_07
				SetVariable NumIon7, disable=0				
			else
				PMT_07		= TTL_00
				NumIon[6]=0
				SetVariable NumIon7, disable=2
			endif
			break	
		case "PMT8box":
			if(checked)
				PMT_08		= DI_08
				SetVariable NumIon8, disable=0				
			else
				PMT_08	= TTL_00
				NumIon[7]=0
				SetVariable NumIon8, disable=2
			endif
			break
	endswitch
	
	WAVE PMT_wave
	PMT_wave={PMT,PMT_01,PMT_02,PMT_03,PMT_04,PMT_05,PMT_06,PMT_07,PMT_08} 
	DoUpdate
	Variable i=1
	For(i=1;i!=9;i+=1)
		NVAR PMT_temp	=	root:ExpParams:$("PMT_0"+num2str(i))
		if(PMT_temp)
			PMT	=	 PMT|PMT_temp
		endif
	Endfor
	PMT_wave={PMT,PMT_01,PMT_02,PMT_03,PMT_04,PMT_05,PMT_06,PMT_07,PMT_08} 
	DoUpdate
end

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
//Procedures to stop scan()
//_____________________________________________________________________________
//
Function EndScanProc(but) : ButtonControl
	STRUCT WMButtonAction &but
	switch( but.eventCode )	
		case 2: // mouse up
			AWGclose
			Abort "Scan Stopped"
			break
		case -1:
			break
	endswitch	
End
//_____________________________________________________________________________
//
//	Procedures for Alignment Sweeper button - uploads sequence to fpga and starts alignment sweeper
//_____________________________________________________________________________
//
Function AlignmentProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	setDatafolder root:ExpParams
	switch( ba.eventCode )	
		case 2: // mouse up
			string windows= WinList("AlignPref"," ; ","")
			if	(strlen(windows)>0)
				KillWindow AlignPref
			endif
			STRUCT Experiment expt
			// Instantiate the Experiment structure with loaded sequence
			GetExperiment(expt)
			// Load the control and scan parameters into the Experiment structure
			GetExperimentParameters(expt)
//			ConstructAWGWaveform(expt)
//			AWGopen
//			AWGUploadWaveform()
			// Export Experiment structure
			// String timeStampedFilename = getTimeStamp()+"_ExptStruct.txt"
			String timeStampedFilename = "CurrentExperiment.txt"
			ExportExptToJSONFile(expt, timeStampedFilename)
			RunAlignmentSweep(expt)
			break
		case -1:
			break
	endswitch
End

//_____________________________________________________________________________
//
//	RunAlignmentSweep will run the sequence without updating scan values and will do so endlessly until stopped by user
//_____________________________________________________________________________
//
Function RunAlignmentSweep(expt)
	STRUCT Experiment &expt
	STRUCT Experiment Temp
	
	Temp=expt
	
	setDatafolder root:Sequencer
	Variable i
	
	SVAR ScanVarName	= root:sequencer:alignmentsweeper:ScanVarName
	WAVE dataScanVar	=root:sequencer:alignmentsweeper:dataScanVar
	NVAR WindowLimit	= root:sequencer:alignmentsweeper:ALIGNSWEEP_POINTS
	SVAR SEQ_PORT=root:ExpParams:SEQ_PORT
	string seq_p = SEQ_PORT	
	VDT2/P=$seq_p baud=230400,stopbits=2,killio
	VDTOpenPort2 $seq_p
	VDTOperationsPort2 $seq_p
	AWGopen
	
	Redimension/N=0 dataScanVar
	
	STRUCT ExOp cOp;                                // this is the dummy exop element that will be used to update the devices.

	wave out = RunExpValues(Temp)  // this one does update the FPGAs and the DDSs for real !!
	AlignSweepDataHandler(out,init=1)  // this functions updates data values for displays
	AlignDataDisplay()    // This function creates the window for displaying the alignment sweeper data frame only at the beginning
	
	Variable j=0
	KeyToAbort(1)  // prints a dialogue box saying how to abort the scan
	do
		if (KeyToAbort(2)==-1)   // If some key is pressed the flag is -1 which means the align sweep stops.
			Print "Success!"
			KeyToAbort(3)    // kills the PressKey2Abort window.
			Execute "SaveBasisHistogram()"
			//flag=1
			
			break    // jumps out of do-while loop.
		endif
		wave out = RunExpValues(Temp)  // this one does update the FPGAs and the DDSs for real !!
		Redimension/N=(Dimsize(dataScanVar,0)+1) dataScanVar
		dataScanVar[(DimSize(dataScanVar,0)-1)]=j
		j+=1
		AlignSweepDataHandler(out)
		DoUpdate
	while(1)
//	UpdateTTL() // reset ttls  only if override option for the TTLs is checked at the override window.

	VDTClosePort2 $seq_p
	AWGclear
	AWGclose	
	//print "Scan Complete"
End

//_____________________________________________________________________________
//
//	Procedures for Scan button - Builds gui to set save and data handling preferences
//_____________________________________________________________________________
//
Function ScanProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	setDatafolder root:ExpParams
	switch( ba.eventCode )	
		case 2: // mouse up
			string windows= WinList("SaveBasisHistogram"," ; ","")
			if	(strlen(windows))
				KillWindow SaveBasisHistogram
			endif			
			DataPrefGUI()
			break
		case -1:
			break
	endswitch	
End

Function AlignScanProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	setDatafolder root:ExpParams
	switch( ba.eventCode )	
		case 2: // mouse up
			string windows= WinList("SaveBasisHistogram"," ; ","")
			if	(strlen(windows))
				KillWindow SaveBasisHistogram
			endif
			AlignPrefGUI()
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
			string windows= WinList("DataPref"," ; ","")
			if	(strlen(windows))
				KillWindow DataPref
			endif
			STRUCT Experiment expt
			// Instantiate the Experiment structure with loaded sequence
			GetExperiment(expt)
			// Load the control and scan parameters into the Experiment structure
			GetExperimentParameters(expt)
			// Export Experiment structure
			// String timeStampedFilename = getTimeStamp()+"_ExptStruct.txt"
			String timeStampedFilename = "CurrentExperiment.txt"
			ExportExptToJSONFile(expt, timeStampedFilename)
			RunExperiment(expt)
			break
		case -1:
			break
	endswitch	
End


//_____________________________________________________________________________
//
//	RunExperiment(expt) creates a dummy Experiment structure based on the current sequence type such that devices and TTLs can be updated
//_____________________________________________________________________________
//
Function RunExperiment(expt)
	STRUCT Experiment &expt
	
	setDatafolder root:Sequencer
	Variable i
	
	SVAR ScanVarName	= root:sequencer:data:ScanVarName
	WAVE dataScanVar	=root:sequencer:data:dataScanVar
	SVAR SEQ_PORT=root:ExpParams:SEQ_PORT
	string seq_p = SEQ_PORT
	string HiResScan
//	VDT2/P=$seq_p baud=230400,stopbits=2,killio
//	VDTOpenPort2 $seq_p
//	VDTOperationsPort2 $seq_p
	AWGopen
	
	Redimension/N=0 dataScanVar
	
	STRUCT ExOp cOp;                                // this is the dummy exop element that will be used to update the devices.
	
	for (i=0;i<expt.numExOps;i+=1)
		cOp = expt.ExOps[i]
		if(cOp.Scanned == 1)                     // scanned flag is  up\
			sprintf HiResScan, "%.4f",cOp.ScanStart	
			expt.ExOps[i].Values = ReplaceListItem(cOp.Values, HiResScan, cOp.ScanParameter) // Replace the "Scan parameter "th values by "Scan start" value
			ScanVarName =StringFromList(cOp.ScanParameter, expt.ExOps[i].ControlParameters) // returns scanning parameter name  ex; "Duration"
			Redimension/N=(Dimsize(dataScanVar,0)+1) dataScanVar
			if(stringmatch("Duration",ScanVarName))            
				dataScanVar[(DimSize(dataScanVar,0)-1)]	= cOp.ScanStart// Writing it down in units of seconds
			else
				dataScanVar[(DimSize(dataScanVar,0)-1)]	= cOp.ScanStart// if not duration leave the units as it is.
			endif
		endif
	endfor
	// creates the statistics of the date sent to it
	//AWGopen
	wave out = RunExpValues(expt)  
	dataHandler(out,init=1)
	dataDisplay()   // This function creates the window for displaying scan data
	variable flag=0
	KeyToAbort(1)
	do
		if (flag)
			Print "Success!"
			break
		endif
		for (i=0;i<expt.numExOps;i+=1)
			if (KeyToAbort(2)==-1)
				Print "Success!"
				KeyToAbort(3)
				flag=1
				break
			endif
			cOp = expt.ExOps[i]
			if(cOp.Scanned == 1)
				Variable nVal = str2num(StringFromList(cOp.ScanParameter, cOp.Values)) + cOp.ScanInc // incremented scan parameter value
				if(nVal > cOp.ScanStop)
					expt.ExOps[i].Values = ReplaceListItem(cOp.Values, num2str(cOp.ScanStart), cOp.ScanParameter) // values for the scannable parameter 
					continue
				else
					Redimension/N=(Dimsize(dataScanVar,0)+1) dataScanVar // incrementing the length of dataScanVar
					if(stringmatch("Duration",ScanVarName))
						dataScanVar[(DimSize(dataScanVar,0)-1)]	= nVal
					else
						dataScanVar[(DimSize(dataScanVar,0)-1)]	= nVal
					endif
					sprintf HiResScan, "%.4f",nVal	
					expt.ExOps[i].Values = ReplaceListItem(cOp.Values, HiResScan, cOp.ScanParameter)
					wave out = RunExpValues(expt)  // this updates the FPGAs and the DDSs for real !!
					dataHandler(out) // analyzes the data and also creates data handling windows which hold histograms and averages
					ScanVarName =StringFromList(cOp.ScanParameter, expt.ExOps[i].ControlParameters)
					//Print ScanVarName
					DoUpdate
					//print "here"
					break
				endif
			endif
		endfor
	while(i < expt.numExOps)
	//UpdateTTL() // reset ttls  only if override option for the TTLs is checked at the override window.
	DeletePoints (DimSize(dataScanVar,0)-1),1,dataScanVar
//	VDTClosePort2 $seq_p
	awgclear
	AWGclose
	KeyToAbort(3)
//	CurveFit/NTHR=0/TBOX=1 sin  ::Sequencer:Data:dataAvg_01 /X=::Sequencer:Data:dataScanVar /D /F={0.990000, 4}
	print "Scan Complete"
End

// replaces part of string numbered p in s1 with string s2.
// eg. ReplaceListItem("1;2;3;4", 100, 2) = 1;2;100;4
Function/S ReplaceListItem(s1, s2, p)
	String s1
	String s2
	Variable p
	
	return AddListItem(s2, RemoveListItem(p, s1), ";", p)
End
//_____________________________________________________________________________
//
//	RunExpValues(expt)  this one looks for the new values of the parameters and updates TTL story and DDS values and triggers FPGA by calling the runSequence function which also returns an array of PMT counts as data.
//_____________________________________________________________________________
Function/WAVE RunExpValues(expt)
	STRUCT Experiment &expt
	
	setDatafolder root:Sequencer
//	SVAR SEQ_PORT
//	String seq_p = SEQ_PORT
	WAVE DDS_INFO = root:ExpParams:DDS_INFO  // the frequency phase ampltitude of the DDSs
	WAVE DDSNames = root:ExpParams:DDSNames //  names of the DDSs
	WAVE TTLNames = root:ExpParams:TTLNames // indices corresponding to chapter names
	WAVE NameWave = root:ExpParams:NameWave    // TTls conrresponding to chapter names
	WAVE OverrideWave = root:ExpParams:OverrideWave  // the ttl ouput values when overriden

	wave awgwave			=	root:awg:awgwaveform
	wave uploadwave		=	root:awg:uploadwave
	
	Redimension/N=0 awgwave
	Redimension/N=0 uploadwave

	NVAR PMT_mask = root:ExpParams:PMT
	
	Variable AWGupdate=0
	Variable mask = 0
	Variable enable = 0
	Variable n,m,i,j=0;
	
	make/o/N=(expt.numExOps,2) SBC_steps		=	 0
	make/o/N=(expt.numExOps,2) Rot_steps		=	 0
	make/o/N=(expt.numExOps,2) uWave_steps		=	 0
	
	For(i=0; i<16; i+=1)
		If(OverrideWave[i][1] && OverrideWave[i][0])         // setting the ,ask dependent on which ttl is overriden
			//Constant port = $("TTL_0"+num2str(i+1))
			mask = mask | 2^(i)
			enable = enable | 2^(i)
		Elseif(OverrideWave[i][1])
			//Constant port = $("TTL_0"+num2str(i+1))
			mask = mask | 2^(i)
		endif
	EndFor

	Make/D/O/N=(expt.numExOps,2)/I/U fpgaSeq // unsigned 32-bit   ; we have 2 columns and rows equal to number of exops
	STRUCT ExOp cOp;
	variable cur_ttl = 0; // this keeps track of the actual number of ttl pulses, as opposed to the chapter
	for (i=0;i<expt.numExOps;i+=1)
		cOp = expt.ExOps[i]
		
		FindValue/TEXT=cOp.name TTLNames  // which one of the TTL name you are choosing
		Variable ttlNo = V_value // the number that can correspond to a TTL name
		fpgaSeq[cur_ttl][0] = (NameWave[ttlNo] & ~mask) | enable // name wave corresponds to the actual TTLs corresponding to indices
		fpgaSeq[cur_ttl][1] = str2num(StringFromList(0, cOp.Values)) *50  // take the duration from the values in us and convert it to clock cycles (20ns)
		strswitch(cOp.device[0,2])
			case "DDS":  // in case of DDS the frequency of a certain DDS gets overwritten
				Variable ddsNo = str2num(cOp.device[3,strlen(cOp.device)-1])
				//print strlen(cOp.device)-1
				//print num2str(ddsNo) + ":" + StringFromList(2, cOp.Values)
				if(DDS_INFO[ddsNo][3] == 0) // if not overridden
					Variable frequency = str2num(StringFromList(2, cOp.Values))
					//print frequency
					Variable phase = str2num(StringFromList(3, cOp.Values))
					Variable amplitude = str2num(StringFromList(1, cOp.Values))
					setDDS(ddsNo+1,frequency*1000000, phase, amplitude*1023/100) // dds numbers are 1 indexed. freq in hertz . Sets the DDS values to be updated. dds number =1 for RF;dds number =2 for Raman1 etc
				endif
			break
			case "AWG":
				awgupdate=1
				wave ttls = ConstructAWGWaveform(expt, i)
				variable num_ttls = dimsize(ttls, 0)
				if(cmpstr(cOp.name, "SBCooling") == 0)
					InsertPoints/M=0 cur_ttl, num_ttls-1, fpgaSeq
					fpgaSeq[cur_ttl,cur_ttl+num_ttls][0] = (ttls[p-cur_ttl][0]  & ~mask) | enable
					fpgaSeq[cur_ttl,cur_ttl+num_ttls][1] = (ttls[p-cur_ttl][1])
					Redimension/N=0 AWGwave
					cur_ttl += num_ttls - 1;
				endif
			break
		endswitch
		cur_ttl += 1
	endfor
	if (AWGupdate)
		AWGUploadWaveform()
	endif
	
	//SVAR SEQ_PORT=root:ExpParams:SEQ_PORT
	//string seq_p = SEQ_PORT	
	//VDT2/P=$seq_p baud=230400,stopbits=2,killio
	//VDTOpenPort2 $seq_p
	//VDTOperationsPort2 $seq_p
	//Print fpgaSeq	
	sendSequence(fpgaSeq)  // Sends the the updated TTL sequence to FPGA
	//wave out = runSequence(expt.exptsPerPoint, recmask = 0x01000000)
	//return runSequence(expt.exptsPerPoint, recmask =PMT_mask) // this one triggers the fpga once after updating it and the DDSs and returns the long string of data for each PMT count
	return runSequence(expt.exptsPerPoint, recmask =0xFF000000) // this one triggers the fpga once after updating it and the DDSs and returns the long string of data for each PMT count
//	VDTClosePort2 COM18	// rec mask will tell which channel is plotted
	
End

//_____________________________________________________________________________
//
//	GetExperiment(expt) creates an Experiment structure based on the current sequence type
//_____________________________________________________________________________
//
function GetExperiment(expt)
	STRUCT Experiment &expt
	SetDataFolder root:ExpParams
	WAVE sequence = LoadedWave // sequence is 1st column of Loaded wave??
	WAVE/T ExOpNames = TTLNames	
	Variable/G TotalStep	
	TotalStep=FindtotalStep()	
	Make/O/T/N=(TotalStep) ExpSeq = ""
	Variable k
	for (k=0;k<TotalStep;k+=1)
		ExpSeq[k] = ExOpNames[sequence[k]] //  ExpSeq[0]= {"Cool","Pump","MSGate","State Detection"} for example
	endfor	
	//Print ExpSeq
	BuildExperiment(ExpSeq, expt)
End

//_____________________________________________________________________________
//
//	GetExperimentParameters(expt) updates an existing Experiment structure with the 
//	control parameters and scan information from the sequence builder panel
//_____________________________________________________________________________
//
function GetExperimentParameters(expt)                                                                                       // updates the exp structure with values from PULSE PROGRAM window
	
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
			ExOpIdx = str2num(S_Value) // index of the operation
			SplitString/E="setpoint[0-9]+" ctrlName
			SplitString/E="[0-9]+" S_Value
			ExOpParam = str2num(S_Value) // the set point parameters like "Duration=0"; "Amplitude=1"; "Frequency=2" etc.
			ControlInfo/W=$(windowName) $ctrlName
			Value = V_Value
			//printf "%s: ExOpIdx = %d, ExOpParam = %d, Value = %d\r" ctrlName, ExOpIdx, ExOpParam, Value
			String HiResScan
			if (ExOpParam == 0)
				sprintf HiResScan, "%.4f",Value	
				expt.ExOps[ExOpIdx].Values = HiResScan + ";"
			else
				sprintf HiResScan, "%.4f",Value	
				expt.ExOps[ExOpIdx].Values += HiResScan + ";"
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
			expt.ExOps[ExOpIdx].Scanned = 1 // if the scan option is on then Scanned =1 and the scan parameter is for eg. 0 for duration, 2 for frequency etc.
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
		if(GrepString(ctrlName,"Loops")) // not needed for us
			ControlInfo/W=$(windowName) $ctrlName
			expt.exptsPerPoint = V_Value
		endif		
		if(GrepString(ctrlName,"Times"))// non existant for us
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
end
//_____________________________________________________________________________
//
//	Event handler to escape loops
//_____________________________________________________________________________
//
Function KeyToAbort(stage)
	Variable stage
	Variable keys, flag 
	if( stage==1)					// to display abot options in a window
		flag		=	0
		keys	=	0
		Execute "PressKey2Abort()"
		//sleep/s 0.5
	elseif (stage ==2)				// to send back a flag to actually stop scan
		sleep/s 0.1
	 	keys	=	GetKeyState(0)
	 	//print keys
	 	if(keys)	
	 		DoAlert 1, "A key has been pressed, abort current scan?"
	 		if (V_flag ==1)
	 			flag = -1
	 			//PopUpMenu
	 		elseif(V_flag==0)
	 			flag = 0
	 		endif
	 	endif
	 	return flag
	 elseif (stage==3)				// to kill abort options window at the beginning of scans.
	 	string windows= WinList("PressKey2Abort"," ; ","")
		if	(strlen(windows)>0)
			KillWindow PressKey2Abort
		endif
	 endif
End

Function TestForAbort()
	keyToAbort(1)
	Variable i=0
	do
		i+=1
		
		if (KeyToAbort(2)==-1)
			Print "Success!"
			KeyToAbort(3)
			break
		endif
	while(i<100)
end

//_____________________________________________________________________________
//
//	Finds AND RETURNS the total number of steps in the loaded wave
//_____________________________________________________________________________
//
Function FindTotalStep()              // this finds the chapters in the sequence and the total number of chapers in the experiment
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