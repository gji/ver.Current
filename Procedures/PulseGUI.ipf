#pragma rtGlobals=1		// Use modern global access method.


//DDS1 -> AO1
//DDS2 -> AO2
//DDS3 -> 935



//This first Half of code is for the Pulse Creator panel which is used to create pulse sequences (without durations or frequency/amplitude/phase)


//New Item button procedure - Adds new item to pulse sequence
Function ButtonProc_1(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SetDataFolder root:ExpParams
	NVAR VerticalButtonPos
	NVAR StepNum
	switch( ba.eventCode )
		case 2: // mouse up
				VerticalButtonPos+=30
				StepNum+=1
				Button NewItem pos={15,VerticalButtonPos}
				ModifyControl DeleteItem pos={115,VerticalButtonPos}
				ModifyControl SetLoops pos={215,VerticalButtonPos}
				String NextPopName = "Popup"+num2str(StepNum)
				String GroupBoxName = "GroupBox"+num2str(StepNum)
				String StepName= "Step " + num2str(StepNum)
				String CommandPop = "PopupMenu "+ NextPopName +" win=PulseCreator, pos={15,VerticalButtonPos-30}, value=" +"\" Delay; Cool; State Detect; Flouresence Detect; Pump; Cool Shutter; Load Shutter; Raman 1; Raman 2; PMT\"" +",  title=\" "+ StepName+"\" "
				String CommandVar = "SetVariable "+GroupBoxName+" win=PulseCreator, pos={200,VerticalButtonPos-30}, title= \"Group\", size={80,20}, value=_NUM:1 ,limits={1,1024,1}" 
				Execute CommandPop
				Execute CommandVar
				KillControl/W=PulseCreator ExportSeq
				GetWindow PulseCreator wsize
				MoveWindow/W=PulseCreator V_left,V_top,V_left+250,(60+V_top+VerticalButtonPos)*72/ScreenResolution
				ClearLoops()
				doupdate	
		case -1: // control being killed
	endswitch
	return 0
End

//Delete Item button procedure - removes previous item from pulse sequence
Function ButtonProc_2(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	SetDataFolder root:ExpParams
	NVAR VerticalButtonPos
	NVAR StepNum

	switch( ba.eventCode )
		case 2: // mouse up
			If (StepNum>0)
				VerticalButtonPos-=30
				ModifyControl NewItem pos={15,VerticalButtonPos}
				ModifyControl DeleteItem pos={117,VerticalButtonPos}
				ModifyControl SetLoops pos={219,VerticalButtonPos}

				String CurrPopName= "Popup"+num2str(StepNum)
				String CurrGroupBoxName= "GroupBox"+num2str(StepNum)
				String StepName= "Step " + num2str(StepNum)
				String CommandPop= "KillControl/W=PulseCreator "+CurrPopName
				String CommandVar= "KillControl/W=PulseCreator "+CurrGroupBoxName
				Execute CommandPop
				Execute CommandVar
				StepNum-=1
				KillControl/W=PulseCreator ExportSeq
				ClearLoops()
				GetWindow PulseCreator wsize
				MoveWindow/W=PulseCreator V_left,V_top,V_left+250,V_top+50+floor(VerticalButtonPos*0.7)
				doupdate
			Endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Set Loops button procedure - generates loop inputs and export sequence button
Function ButtonProc_3(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SetDataFolder root:ExpParams
	NVAR StepNum
	NVAR GroupError
	NVAR VerticalButtonPos
	
	switch( ba.eventCode )
		case 2: // mouse up
			if (StepNum>1)
				GetGroupVals()
				Ordered()
				If (GroupError==0)
					Incremented()
				Endif
				If (GroupError==0)
					GenerateLoops()
				Endif
			Endif
			GetWindow PulseCreator wsize
			MoveWindow/W=PulseCreator V_left,V_top,V_left+350,V_top+50+floor(VerticalButtonPos*0.7)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Checks if the group numbers are in order
Function Ordered()
	SetDataFolder root:ExpParams
	NVAR StepNum
	WAVE GroupVals
	NVAR GroupError
	Variable i
	
	GroupError=0
	for (i=1;i<StepNum;i+=1)
		If (GroupVals[i-1]>GroupVals[i])
			GroupError=1
		Endif
	endFor
	If (GroupError==1)
		DoAlert/T="Grouping Error" 0, "Groups Out of Order"
	Endif
End


//Checks to make sure the group numbers do not skip a number
Function Incremented()
	SetDataFolder root:ExpParams
	NVAR StepNum
	WAVE GroupVals
	NVAR GroupError
	Variable i
	
	for (i=1;i<StepNum;i+=1)
			If (GroupVals[i-1] != GroupVals[i] && GroupVals[i-1]!= GroupVals[i]-1)
				
				GroupError=1
			Endif
	endFor
	If (GroupError==1)
		DoAlert/T="Grouping Error" 0, "Groups Not Incremented by 1"
	Endif
End

//Grabs operation names
Function GetPopupVals()
SetDataFolder root:ExpParams
	NVAR StepNum
	WAVE NameWave
	Variable i
	Make/O/N=(StepNum) PopupVals=0
		Variable Value
	
	For(i=0 ; i< StepNum ; i+=1)
		String GetPopupVal = "ControlInfo Popup"+num2str(i+1)+" ; Value= V_Value; PopupVals["+num2str(i)+"]=Value-1"
		Execute GetPopupVal
	EndFor
End

//Grabs group number for each operation
Function GetGroupVals()
	SetDataFolder root:ExpParams
	NVAR StepNum
	Variable i
	Make/O/N=(StepNum) GroupVals=0
		Variable Value

	For(i=0 ; i< StepNum ; i+=1)
		String GetGroupVal = "ControlInfo GroupBox"+num2str(i+1)+" ; Value= V_Value; GroupVals["+num2str(i)+"]=Value"
		Execute GetGroupVal
	EndFor
End

//Grabs the loop numbers for each group
Function GetLoopVals()
	SetDataFolder root:ExpParams
	NVAR GroupNumber
	Variable i
	Make/O/N=(GroupNumber) LoopVals=0
		Variable Value

	For(i=0 ; i< GroupNumber ; i+=1)
		String GetLoopVal = "ControlInfo LoopGroup"+num2str(i+1)+" ; Value= V_Value; LoopVals["+num2str(i)+"]=Value"
		Execute GetLoopVal
	EndFor
End

//Generates the loop input controls
Function GenerateLoops()
	SetDataFolder root:ExpParams
	NVAR StepNum
	NVAR GroupNumber
	NVAR VerticalButtonPos
	NVAR VerticalLoopPosition
	WAVE GroupVals
	Variable i=0
	
	GroupNumber=GroupVals[StepNum]
	VerticalLoopPosition=16	
	ClearLoops()
	
	For (i=0;i<GroupNumber;i+=1)
		VerticalLoopPosition+=30
		String CommandLoop = "SetVariable LoopGroup"+num2str(i+1)+" win=PulseCreator,pos={321,VerticalLoopPosition-30},title=\"Group "+num2str(i+1)+" Loops\", size={120,20}, value=_NUM:1, limits={1,1024,1}"
		Execute CommandLoop
	EndFor
	Button ExportSeq win=PulseCreator,appearance={native}, proc=ButtonProc_4, pos={321,VerticalButtonPos},title="Export Sequence", size={100,20}
	
End

//Deletes all loop controls
Function ClearLoops()
	SetDataFolder root:ExpParams
	Variable i=0
	
	For (i=0; i<1024;i+=1)
		String KillLoop = "KillControl/W=PulseCreator LoopGroup"+num2str(i+1)
		Execute KillLoop
	EndFor
End

//Export Sequence button procedure - exports sequence
Function ButtonProc_4(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SetDataFolder root:ExpParams
	NVAR StepNum
	NVAR GroupNumber
	NVAR GroupError
	WAVE GroupVals
	NVAR TooLong	
	WAVE PulseCreatorWave
	switch( ba.eventCode )
		case 2: // mouse up
			GroupError=0
			DoWindow/K SaveWaveWindow
		
			GetGroupVals()
			If (GroupVals[StepNum-1]!=GroupNumber)
				GroupError=1
				DoAlert/T="Grouping Error" 0, "Set Loops"
			Endif
			If (GroupError==0)
				Ordered()
			Endif
			If (GroupError==0)
				Incremented()
			Endif
			If (GroupError!=0)
				KillControl/W=PulseCreator ExportSeq
			Else
				TestWaveSize()
				If (TooLong==0)
					CreateWave()
					Execute "SaveWaveWindow()"
				Endif
			Endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Checks to make sure that the exported sequence is not longer than the size allowed by the FPGA
Function TestWaveSize()
	SetDatafolder root:ExpParams
	WAVE PopupVals
	WAVE GroupVals
	WAVE LoopVals
	NVAR StepNum
	NVAR GroupNumber
	NVAR TooLong
	
	Variable TotalSize=0
	Variable GroupSize=1
	Variable CurrentGroup=1
	Variable i	
	
	GetPopupVals()
	GetGroupVals()
	GetLoopVals()
	
	TooLong=0
	For (i=0;i<StepNum-1;i+=1)
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
End

//Takes info from the step name, group numbers, and loop numbers and creates a wave
Function CreateWave()
	SetDataFolder root:ExpParams
	WAVE PopupVals
	WAVE GroupVals
	WAVE LoopVals
	WAVE PulseCreatorWave
	NVAR StepNum
	NVAR GroupNumber
	Variable GroupSize=1
	Variable i,j,k
	
	
	PulseCreatorWave=0
	
	GetPopupVals()
	GetGroupVals()
	GetLoopVals()
	
	For (i=0;i<StepNum;i+=1)
		PulseCreatorWave[i][0]=PopupVals[i]
		Print PopupVals[i]
	EndFor
	
	For (j=0;j<StepNum;j+=1)
		PulseCreatorWave[j][1]=GroupVals[j]
	EndFor
	
	For (k=0;k<GroupNumber;k+=1)
		PulseCreatorWave[k][2]=LoopVals[k]
	EndFor
	
End

//Creates a window with options to save the wave
Window SaveWaveWindow() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(806,108,1138,208) as "Save Sequence as..."
	SetVariable WaveSaveName pos={100,17.5},size={195,20},BodyWidth=185,title="Sequence Name:",value=_STR:"SequenceName"
	Button WaveSaveButton pos={197.5,57.5},size={100,20},title="Save Sequence",proc=ButtonProc_5
EndMacro

//Save Button procedure - Saves the wave
Function ButtonProc_5(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SetDataFolder root:ExpParams
	WAVE PulseCreatorWave
	String SequenceName
	
	switch( ba.eventCode )	
		case 2: // mouse up
	ControlInfo WaveSaveName
	SequenceName=S_Value
	Save/P=SavePath/O/G/W PulseCreatorWave as SequenceName+".dat"
	DoAlert/T="Save Message" 0, "Pulse Sequence Saved as "+SequenceName+".dat"
	DoWindow/K SaveWaveWindow
			break
		case -1: // control being killed
			break
	endswitch
End


//
//
//This second half of code is for the Pulse program panel which is used to set parameters for a pulse sequence and send them to the fpga to be run
//
//


//Sequence Popup Menu Control - Generates titles, scan options, cycles and run controls
Function PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	SetDataFolder root:ExpParams
	Make/O/N=(1024,3) LoadedWave 
	WAVE wave0
	Variable i
	

	switch( pa.popNum )
		case 1: // mouse up
			ClearScanControls()
			MoveWindow/W=Pulse 0,0,333,100
			break
		case 2: // control being killed
			ClearScanControls()
			Wave0=0
			LoadedWave=0
			LoadWave/D/H/J/M/P=SavePath/N/G "TestSequence.dat"
			LoadedWave=Wave0
			
			GenerateScanControls(LoadedWave,DefaultSettings())
			CreateButtons()
			ControlInfo SetScan
			GetWindow Pulse wsize
			MoveWindow/W=Pulse V_left,V_top,V_left+250,(60+V_top+VerticalButtonPos)*72/ScreenResolution
						
//			PopupMenu SelectSettings value=" ; Settings 1 ; Settings 2 ; Settings 3 ;...", popvalue=" "
			break
		case 3:
			ClearScanControls()
			Wave0=0
			LoadedWave=0
			LoadWave/D/H/J/M/P=SavePath/N/G "TestFinalSequence.dat"
			LoadedWave=Wave0
			
			GenerateScanControls(LoadedWave,DefaultSettings())
			CreateButtons()
			MoveWindow/W=Pulse 0,0,900,550
			
			break
		case 4:
			ClearScanControls()
			Wave0=0
			LoadedWave=0
			LoadWave/D/H/J/M/P=SavePath/N/G "PMT Test.dat"
			LoadedWave=Wave0
			
			GenerateScanControls(LoadedWave,DefaultSettings())
			CreateButtons()
			MoveWindow/W=Pulse 0,0,900,550
			break
		case 5:
			break
	endswitch
	
	return 0
End

//Cycles through passed wave and generates title and scan controls for each item
Function GenerateScanControls(load,settingwave)
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
	NVAR StepN
	NVAR VerticalButtonPosition
	NVAR DDS1Counter,DDS2Counter,DDS3Counter,DDS7Counter,DDS8counter
	String Makegrouptitle
	ClearScanControls()
	DDS1Counter=0
	DDS2Counter=0
	DDS3Counter=0
	DDS7Counter=0
	DDS8Counter=0
	
	Variable i,j
	Variable/G TotalStep	
	StepN=1
	TotalStep=FindtotalStep()
	VerticalButtonPosition=76
	
	TitleBox Group1Title,frame=4,fixedSize=1,labelBack=(0,0,0),fColor=(65535,65535,65535),anchor=MC,pos={75,VerticalButtonPosition-30},size={150,20}, title="Group: "+num2str(load[0][1])+" Loops: "+num2str(load[load[0][1]-1][2])
	
	For (j=0; j<TotalStep; j+=1)
		If (j>0)
			If (load[j][1]!=load[j-1][1])
			Makegrouptitle= "TitleBox Group"+num2str(load[j][1])+"Title, fixedSize=1,frame=4,labelBack=(0,0,0),fColor=(65535,65535,65535),anchor=MC,pos={75,VerticalButtonPosition},size={150,20}, title=\"Group: "+num2str(load[j][1])+" Loops: "+num2str(load[load[j][1]-1][2])+"\""
			Execute Makegrouptitle
			VerticalButtonPosition+=30
			Endif
		Endif
		StepN=j+1
		GenerateScan(load[j][0],j,settingwave)
	EndFor
	
End


//generates title and scan controls for a passed operation name
Function GenerateScan(name,step,settingwave)
	WAVE settingwave
	Variable name,step
	SetDataFolder root:ExpParams
	NVAR VerticalButtonPosition
	NVAR StepN
	WAVE/T TTLNames
	NVAR DDS1Counter,DDS2Counter,DDS3Counter
	NVAR DDS7Counter,DDS8counter
	NVAR filler
	WAVE Settings
	String Scan0Command 
	String Scan1Command 
	String Scan2Command 
	String Scan3Command 
	String Scan4Command 
	String Scan5Command
	String Count,Counting
	filler=0


	String TitleBoxCommand = "TitleBox Step"+num2str(StepN)+"Title,labelBack=(65535,65535,65535),frame=5, fixedSize=1,anchor=MC,pos={15,VerticalButtonPosition},size={150,20}, title=\""+TTLNames[name]+"\",win=Pulse"
	Execute TitleBoxCommand
	If (name==1||name==7||name==8)
		Scan0Command = "CheckBox Step"+num2str(StepN)+"Scan0, pos={170,VerticalButtonPosition+4}, title=\"Duration\", win=Pulse,value="+num2str(settingwave[5*step+1][0])
		Scan1Command = "CheckBox Step"+num2str(StepN)+"Scan1, pos={170,VerticalButtonPosition+34}, title=\"Scan Fequency\", win=Pulse,value="+num2str(settingwave[5*step+2][0])
		Scan2Command = "CheckBox Step"+num2str(StepN)+"Scan2, pos={170,VerticalButtonPosition+64}, title=\"Scan Amplitude\", win=Pulse,value="+num2str(settingwave[5*step+3][0])
		Scan3Command = "CheckBox Step"+num2str(StepN)+"Scan3, pos={170,VerticalButtonPosition+94}, title=\"Scan Phase\", win=Pulse,value="+num2str(settingwave[5*step+4][0])
		count = "filler=DDS"+num2str(name)+"Counter"
		Execute count
		If (filler==0)
			counting = "DDS"+num2str(name)+"Counter+=1"
			Execute counting
			
			Execute Scan0Command
			Execute Scan1Command
			Execute Scan2Command
			Execute Scan3Command
			VerticalButtonPosition+=120
		Else
			Execute Scan0Command
			VerticalButtonPosition+=30
		Endif
	Elseif(name==2||name==3)
		Scan0Command = "CheckBox Step"+num2str(StepN)+"Scan0, pos={170,VerticalButtonPosition+4}, title=\"Duration\", win=Pulse,value="+num2str(settingwave[5*step+1][0])
		Scan1Command = "CheckBox Step"+num2str(StepN)+"Scan1, pos={170,VerticalButtonPosition+34}, title=\"Scan AO Fequency\", win=Pulse,value="+num2str(settingwave[5*step+2][0])
		Scan2Command = "CheckBox Step"+num2str(StepN)+"Scan2, pos={170,VerticalButtonPosition+64}, title=\"Scan AO Amplitude\", win=Pulse,value="+num2str(settingwave[5*step+3][0])
		Scan3Command = "CheckBox Step"+num2str(StepN)+"Scan3, pos={170,VerticalButtonPosition+94}, title=\"Scan AO Phase\", win=Pulse,value="+num2str(settingwave[5*step+4][0])
		Scan4Command = "CheckBox Step"+num2str(StepN)+"Scan4, pos={170,VerticalButtonPosition+124}, title=\"Scan EO Fequency\", win=Pulse,value="+num2str(settingwave[5*step+2][0])
		Scan5Command = "CheckBox Step"+num2str(StepN)+"Scan5, pos={170,VerticalButtonPosition+154}, title=\"Scan EO Amplitude\", win=Pulse,value="+num2str(settingwave[5*step+3][0])
		count = "filler=DDS"+num2str(name)+"Counter"
		Execute count
		If (filler==0)
			counting = "DDS"+num2str(name)+"Counter+=1"
			Execute counting
			
			Execute Scan0Command
			Execute Scan1Command
			Execute Scan2Command
			Execute Scan3Command
			Execute Scan4Command
			Execute Scan5Command
			VerticalButtonPosition+=180
		Else
			Execute Scan0Command
			VerticalButtonPosition+=30
		Endif
	Else
		String ScanCommand = "CheckBox Step"+num2str(StepN)+"Scan, pos={170,VerticalButtonPosition+4}, title=\"Scan Duration\", win=Pulse,value="+num2str(settingwave[5*step][0])
		Execute ScanCommand
		VerticalButtonPosition+=30
	Endif
End

//Deletes all current scan controls, titles, buttons, and loops
Function ClearScanControls()
Variable i
	For (i=0;i<=FindTotalStep();i+=1)
		String killtitle = "KillControl/W=Pulse Step"+num2str(i)+"Title"
		String kill = "KillControl/W=Pulse Step"+num2str(i)+"Scan"
		String kill0 = "KillControl/W=Pulse Step"+num2str(i)+"Scan0"
		String kill1= "KillControl/W=Pulse Step"+num2str(i)+"Scan1"
		String kill2= "KillControl/W=Pulse Step"+num2str(i)+"Scan2"
		String kill3 = "KillControl/W=Pulse Step"+num2str(i)+"Scan3"	
		String kill4 = "KillControl/W=Pulse Step"+num2str(i)+"Scan4"
		String kill5 = "KillControl/W=Pulse Step"+num2str(i)+"Scan5"
		String killlower0 = "KillControl/W=Pulse Step"+num2str(i)+"lowerlim0"
		String killlower1 = "KillControl/W=Pulse Step"+num2str(i)+"lowerlim1"
		String killlower2= "KillControl/W=Pulse Step"+num2str(i)+"lowerlim2"
		String killlower3= "KillControl/W=Pulse Step"+num2str(i)+"lowerlim3"
		String killlower = "KillControl/W=Pulse Step"+num2str(i)+"lowerlim"
		String killupper = "KillControl/W=Pulse Step"+num2str(i)+"upperlim"
		String killupper0= "KillControl/W=Pulse Step"+num2str(i)+"upperlim0"
		String killupper1= "KillControl/W=Pulse Step"+num2str(i)+"upperlim1"
		String killupper2= "KillControl/W=Pulse Step"+num2str(i)+"upperlim2"
		String killupper3 = "KillControl/W=Pulse Step"+num2str(i)+"upperlim3"
		String killinc = "KillControl/W=Pulse Step"+num2str(i)+"Inc"
		String killinc0 = "KillControl/W=Pulse Step"+num2str(i)+"Inc0"
		String killinc1 = "KillControl/W=Pulse Step"+num2str(i)+"Inc1"
		String killinc2 = "KillControl/W=Pulse Step"+num2str(i)+"Inc2"
		String killinc3 = "KillControl/W=Pulse Step"+num2str(i)+"Inc3"
		String killset = "KillControl/W=Pulse Step"+num2str(i)+"setpoint"
		String killset0 = "KillControl/W=Pulse Step"+num2str(i)+"setpoint0"
		String killset1 = "KillControl/W=Pulse Step"+num2str(i)+"setpoint1"
		String killset2 = "KillControl/W=Pulse Step"+num2str(i)+"setpoint2"
		String killset3 = "KillControl/W=Pulse Step"+num2str(i)+"setpoint3"
		String killSO = "KillControl/W=Pulse Step"+num2str(i)+"ScanOrder"
		String killSO0 = "KillControl/W=Pulse Step"+num2str(i)+"ScanOrder0"
		String killSO1 = "KillControl/W=Pulse Step"+num2str(i)+"ScanOrder1"
		String killSO2 = "KillControl/W=Pulse Step"+num2str(i)+"ScanOrder2"
		String killSO3 = "KillControl/W=Pulse Step"+num2str(i)+"ScanOrder3"
		Execute killSO1+";"+killSO2+";"+killSO3+";"+killSO+";"+killSO0
		Execute killtitle+";"+killlower+";"+killlower1+";"+killlower2+";"+killlower3+";"+killlower0
		Execute killupper+";"+killupper1+";"+killupper2+";"+killupper3+";"+killinc+";"+killinc1+";"+killinc0+";"+killupper0
		Execute killinc2+";"+killinc3+";"+killset+";"+killset1+";"+killset2+";"+killset3+";"+killset0+";"+kill0
		Execute kill
		Execute kill1
		Execute kill2
		Execute kill3
		KillControl/W=Pulse Loops
		KillControl/W=Pulse SetScan
		KillControl/W=Pulse ClearScan
		KillControl/W=Pulse Run
		KillControl/W=Pulse LoadSettings
		KillControl/W=Pulse SaveSettings
//		PopupMenu SelectSettings popvalue=" ", value=" "
	EndFor
//	PopupMenu Sequence popmatch=" ", win=Pulse

	For(i=1;i<=TotalGroupNumber();i+=1)
		String killgrouptitle = "KillControl/W=Pulse Group"+num2str(i)+"Title"
		Execute killgrouptitle
	Endfor
End

//Resets to before scan bounds were generated
Function ClearScanBounds()
Variable i
	For (i=0;i<=FindtotalStep();i+=1)
		String killlower0 = "KillControl/W=Pulse Step"+num2str(i)+"lowerlim0"
		String killlower1 = "KillControl/W=Pulse Step"+num2str(i)+"lowerlim1"
		String killlower2= "KillControl/W=Pulse Step"+num2str(i)+"lowerlim2"
		String killlower3= "KillControl/W=Pulse Step"+num2str(i)+"lowerlim3"
		String killlower = "KillControl/W=Pulse Step"+num2str(i)+"lowerlim"
		String killupper = "KillControl/W=Pulse Step"+num2str(i)+"upperlim"
		String killupper0= "KillControl/W=Pulse Step"+num2str(i)+"upperlim0"
		String killupper1= "KillControl/W=Pulse Step"+num2str(i)+"upperlim1"
		String killupper2= "KillControl/W=Pulse Step"+num2str(i)+"upperlim2"
		String killupper3 = "KillControl/W=Pulse Step"+num2str(i)+"upperlim3"
		String killinc = "KillControl/W=Pulse Step"+num2str(i)+"Inc"
		String killinc0 = "KillControl/W=Pulse Step"+num2str(i)+"Inc0"
		String killinc1 = "KillControl/W=Pulse Step"+num2str(i)+"Inc1"
		String killinc2 = "KillControl/W=Pulse Step"+num2str(i)+"Inc2"
		String killinc3 = "KillControl/W=Pulse Step"+num2str(i)+"Inc3"
		String killset = "KillControl/W=Pulse Step"+num2str(i)+"setpoint"
		String killset0 = "KillControl/W=Pulse Step"+num2str(i)+"setpoint0"
		String killset1 = "KillControl/W=Pulse Step"+num2str(i)+"setpoint1"
		String killset2 = "KillControl/W=Pulse Step"+num2str(i)+"setpoint2"
		String killset3 = "KillControl/W=Pulse Step"+num2str(i)+"setpoint3"
		String killSO = "KillControl/W=Pulse Step"+num2str(i)+"ScanOrder"
		String killSO0 = "KillControl/W=Pulse Step"+num2str(i)+"ScanOrder0"
		String killSO1 = "KillControl/W=Pulse Step"+num2str(i)+"ScanOrder1"
		String killSO2 = "KillControl/W=Pulse Step"+num2str(i)+"ScanOrder2"
		String killSO3 = "KillControl/W=Pulse Step"+num2str(i)+"ScanOrder3"
		Execute killSO1+";"+killSO2+";"+killSO3+";"+killSO+";"+killSO0
		Execute killlower+";"+killlower1+";"+killlower2+";"+killlower3+";"+killlower0
		Execute killupper+";"+killupper1+";"+killupper2+";"+killupper3+";"+killinc+";"+killinc1+";"+killinc0+";"+killupper0
		Execute killinc2+";"+killinc3+";"+killset+";"+killset1+";"+killset2+";"+killset3+";"+killset0
	EndFor
End

//Dynamically Generates Scan bounds or set points based on selected scan parameters
Function GenerateBounds(load,settingwave)
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
	NVAR DDS1Counter,DDS2Counter,DDS3Counter,DDSCounted
	NVAR filler
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
	String generatesetpoint5
				
	
	DDS1Counter=0
	DDS2Counter=0
	DDS3Counter=0
	DDSCounted=0
	
	VerticalButtonPosition=76
	TotalScan=0
	For (i=0;i<TotalStep;i+=1)
		If (i>0)
			If (load[i][1]!=load[i-1][1])
			VerticalButtonPosition+=30
			Endif
		Endif
			If (load[i][0]==1||load[i][0]==7||load[i][0]==8)
				
				
				 getscan0 = "ControlInfo Step"+num2str(i+1)+"Scan0;value0=V_Value"
				 getscan1 = "ControlInfo Step"+num2str(i+1)+"Scan1;value1=V_Value"
				 getscan2 = "ControlInfo Step"+num2str(i+1)+"Scan2;value2=V_Value"
				 getscan3 = "ControlInfo Step"+num2str(i+1)+"Scan3;value3=V_Value"
				Execute getscan0
				Execute getscan1
				Execute getscan2
				Execute getscan3
				

				 generatelowlim0 = "SetVariable Step"+num2str(i+1)+"lowerlim0, pos={500, VerticalButtonPosition}, title=\"Start Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][2])
				 generatelowlim1 = "SetVariable Step"+num2str(i+1)+"lowerlim1, pos={500, VerticalButtonPosition+30}, title=\"Start Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+2][2])
				 generatelowlim2 = "SetVariable Step"+num2str(i+1)+"lowerlim2, pos={500, VerticalButtonPosition+60}, title=\"Start Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+3][2])+",limits={0,1023,1}"
				 generatelowlim3 = "SetVariable Step"+num2str(i+1)+"lowerlim3, pos={500, VerticalButtonPosition+90}, title=\"Start Phase\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+4][2])
				 generateupperlim0 = "SetVariable Step"+num2str(i+1)+"upperlim0, pos={680, VerticalButtonPosition}, title=\"End Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][3])
				 generateupperlim1 = "SetVariable Step"+num2str(i+1)+"upperlim1, pos={680, VerticalButtonPosition+30}, title=\"End Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+2][3])
				 generateupperlim2 = "SetVariable Step"+num2str(i+1)+"upperlim2, pos={680, VerticalButtonPosition+60}, title=\"End Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+3][3])+",limits={0,1023,1}"
				 generateupperlim3 = "SetVariable Step"+num2str(i+1)+"upperlim3, pos={680, VerticalButtonPosition+90}, title=\"End Phase\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+4][3])
				 generateInc0 = "SetVariable Step"+num2str(i+1)+"Inc0, pos={860, VerticalButtonPosition}, title=\"Increment (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][4])
				 generateInc1 = "SetVariable Step"+num2str(i+1)+"Inc1, pos={860, VerticalButtonPosition+30}, title=\"Increment (MHZ)\", win=Pulse,size={130,20},bodywidth=50,limits={0.001,400,.001},value=_NUM:"+num2str(SettingWave[7*i+2][4])
				 generateInc2 = "SetVariable Step"+num2str(i+1)+"Inc2, pos={860, VerticalButtonPosition+60}, title=\"Increment\", win=Pulse,size={130,20},bodywidth=50,limits={1,1023,1},value=_NUM:"+num2str(SettingWave[7*i+3][4])
				 generateInc3 = "SetVariable Step"+num2str(i+1)+"Inc3, pos={860, VerticalButtonPosition+90}, title=\"Increment (Degrees)\", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=_NUM:"+num2str(SettingWave[7*i+4][4])
				 generateScanOrder0 = "SetVariable Step"+num2str(i+1)+"ScanOrder0, pos={1040, VerticalButtonPosition}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
				 generateScanOrder1 = "SetVariable Step"+num2str(i+1)+"ScanOrder1, pos={1040, VerticalButtonPosition+30}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
				 generateScanOrder2 = "SetVariable Step"+num2str(i+1)+"ScanOrder2, pos={1040, VerticalButtonPosition+60}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
				 generateScanOrder3 = "SetVariable Step"+num2str(i+1)+"ScanOrder3, pos={1040, VerticalButtonPosition+90}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
				
				 generatesetpoint0 = "SetVariable Step"+num2str(i+1)+"setpoint0, pos={320, VerticalButtonPosition}, title=\"Time Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][1])
				 generatesetpoint1 = "SetVariable Step"+num2str(i+1)+"setpoint1, pos={320, VerticalButtonPosition+30}, title=\"Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+2][1])
				 generatesetpoint2 = "SetVariable Step"+num2str(i+1)+"setpoint2, pos={320, VerticalButtonPosition+60}, title=\"Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+3][1])
				 generatesetpoint3 = "SetVariable Step"+num2str(i+1)+"setpoint3, pos={320, VerticalButtonPosition+90}, title=\"Phase\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+4][1])
				
				

				
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
			Elseif(Load[i][0]==1||Load[i][0]==2)	
				
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
				

				 generatelowlim0 = "SetVariable Step"+num2str(i+1)+"lowerlim0, pos={500, VerticalButtonPosition}, title=\"Start Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][2])
				 generatelowlim1 = "SetVariable Step"+num2str(i+1)+"lowerlim1, pos={500, VerticalButtonPosition+30}, title=\"Start AO Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+2][2])
				 generatelowlim2 = "SetVariable Step"+num2str(i+1)+"lowerlim2, pos={500, VerticalButtonPosition+60}, title=\"Start AO Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+3][2])+",limits={0,1023,1}"
				 generatelowlim3 = "SetVariable Step"+num2str(i+1)+"lowerlim3, pos={500, VerticalButtonPosition+90}, title=\"Start AO Phase\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+4][2])
				 generatelowlim4 = "SetVariable Step"+num2str(i+1)+"lowerlim4, pos={500, VerticalButtonPosition+120}, title=\"Start EO Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+5][2])
				 generatelowlim5 = "SetVariable Step"+num2str(i+1)+"lowerlim5, pos={500, VerticalButtonPosition+150}, title=\"Start EO Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+6][2])
				 generateupperlim0 = "SetVariable Step"+num2str(i+1)+"upperlim0, pos={680, VerticalButtonPosition}, title=\"End Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][3])
				 generateupperlim1 = "SetVariable Step"+num2str(i+1)+"upperlim1, pos={680, VerticalButtonPosition+30}, title=\"End AO Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+2][3])
				 generateupperlim2 = "SetVariable Step"+num2str(i+1)+"upperlim2, pos={680, VerticalButtonPosition+60}, title=\"End AO Amplitude (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+3][3])+",limits={0,1023,1}"
				 generateupperlim3 = "SetVariable Step"+num2str(i+1)+"upperlim3, pos={680, VerticalButtonPosition+90}, title=\"End AO Phase\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+4][3])
				 generateupperlim4 = "SetVariable Step"+num2str(i+1)+"upperlim4, pos={680, VerticalButtonPosition+120}, title=\"End EO Frequency\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+5][3])
				 generateupperlim5 = "SetVariable Step"+num2str(i+1)+"upperlim5, pos={680, VerticalButtonPosition+150}, title=\"End EO Amplitude (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+6][3])
				 generateInc0 = "SetVariable Step"+num2str(i+1)+"Inc0, pos={860, VerticalButtonPosition}, title=\"Increment (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][4])
				 generateInc1 = "SetVariable Step"+num2str(i+1)+"Inc1, pos={860, VerticalButtonPosition+30}, title=\"Increment (MHZ)\", win=Pulse,size={130,20},bodywidth=50,limits={0.001,400,.001},value=_NUM:"+num2str(SettingWave[7*i+2][4])
				 generateInc2 = "SetVariable Step"+num2str(i+1)+"Inc2, pos={860, VerticalButtonPosition+60}, title=\"Increment\", win=Pulse,size={130,20},bodywidth=50,limits={1,1023,1},value=_NUM:"+num2str(SettingWave[7*i+3][4])
				 generateInc3 = "SetVariable Step"+num2str(i+1)+"Inc3, pos={860, VerticalButtonPosition+90}, title=\"Increment (Degrees)\", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=_NUM:"+num2str(SettingWave[7*i+4][4])
				 generateInc4 = "SetVariable Step"+num2str(i+1)+"Inc4, pos={860, VerticalButtonPosition+120}, title=\"Increment (MHZ)\", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=_NUM:"+num2str(SettingWave[7*i+5][4])
				 generateInc5 = "SetVariable Step"+num2str(i+1)+"Inc5, pos={860, VerticalButtonPosition+150}, title=\"Increment\", win=Pulse,size={130,20},bodywidth=50,limits={1,360,1},value=_NUM:"+num2str(SettingWave[7*i+6][4])
				 generateScanOrder0 = "SetVariable Step"+num2str(i+1)+"ScanOrder0, pos={1040, VerticalButtonPosition}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
				 generateScanOrder1 = "SetVariable Step"+num2str(i+1)+"ScanOrder1, pos={1040, VerticalButtonPosition+30}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
				 generateScanOrder2 = "SetVariable Step"+num2str(i+1)+"ScanOrder2, pos={1040, VerticalButtonPosition+60}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
				 generateScanOrder3 = "SetVariable Step"+num2str(i+1)+"ScanOrder3, pos={1040, VerticalButtonPosition+90}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
				 generateScanOrder4 = "SetVariable Step"+num2str(i+1)+"ScanOrder4, pos={1040, VerticalButtonPosition+120}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
				 generateScanOrder5 = "SetVariable Step"+num2str(i+1)+"ScanOrder5, pos={1040, VerticalButtonPosition+150}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
								
				 generatesetpoint0 = "SetVariable Step"+num2str(i+1)+"setpoint0, pos={320, VerticalButtonPosition}, title=\"Time Duration (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,2000000,.02},value=_NUM:"+num2str(SettingWave[7*i+1][1])
				 generatesetpoint1 = "SetVariable Step"+num2str(i+1)+"setpoint1, pos={320, VerticalButtonPosition+30}, title=\"AO Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+2][1])
				 generatesetpoint2 = "SetVariable Step"+num2str(i+1)+"setpoint2, pos={320, VerticalButtonPosition+60}, title=\"AO Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+3][1])
				 generatesetpoint3 = "SetVariable Step"+num2str(i+1)+"setpoint3, pos={320, VerticalButtonPosition+90}, title=\"AO Phase\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+4][1])
				 generatesetpoint4 = "SetVariable Step"+num2str(i+1)+"setpoint4, pos={320, VerticalButtonPosition+120}, title=\"EO Frequency (MHZ)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+5][1])
				 generatesetpoint5 = "SetVariable Step"+num2str(i+1)+"setpoint5, pos={320, VerticalButtonPosition+150}, title=\"EO Amplitude\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i+6][1])
				
				

				
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

				String generatelowlim = "SetVariable Step"+num2str(i+1)+"lowerlim, pos={500, VerticalButtonPosition}, title=\"Start Duration (us)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i][2])+",limits={.02,2000000,0.02}"
				String generateupperlim = "SetVariable Step"+num2str(i+1)+"upperlim, pos={680, VerticalButtonPosition}, title=\"End Duration(us)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i][3])+",limits={.02,2000000,0.02}"
				String generateInc = "SetVariable Step"+num2str(i+1)+"Inc, pos={860, VerticalButtonPosition}, title=\"Increment (us)\", win=Pulse,size={130,20},bodywidth=50,limits={.02,20000,.02},value=_NUM:"+num2str(SettingWave[7*i][4])				
				String generatesetpoint = "SetVariable Step"+num2str(i+1)+"setpoint, pos={320, VerticalButtonPosition}, title=\"Time Duration (us)\", win=Pulse,size={130,20},bodywidth=50,value=_NUM:"+num2str(SettingWave[7*i][1])+",limits={.02,2000000,0.002}"
				String generateScanOrder = "SetVariable Step"+num2str(i+1)+"ScanOrder, pos={1040, VerticalButtonPosition}, title=\"Scan Order\", win=Pulse,size={130,20},bodywidth=50,limits={1,1024,1},value=_NUM:"
				
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


//Creates set scan, clear scan, and run buttons and the cycles #
Function CreateButtons()
	SetDataFolder root:ExpParams
	NVAR VerticalButtonPosition
	
	SetVariable Loops pos={542,VerticalButtonPosition},win=Pulse,title="Number of Cycles", limits={0,2^16,1}, size={130,20},value=_NUM:1
	
	VerticalButtonPosition+=30
	
	Button LoadSettings win=Pulse, pos={15,VerticalButtonPosition}, title="Load Settings", proc=LoadSettingsProc ,size={100,20}
	Button SaveSettings win=Pulse, pos={155,VerticalButtonPosition}, title="Save Settings", proc=SaveSettingsProc, size={100,20}
	Button SetScan win=Pulse,pos={435,VerticalButtonPosition}, title="Set Scan", proc=SetScanProc,size={100,20}
	Button ClearScan win=Pulse,pos={295,VerticalButtonPosition}, title="Clear Scan", proc=ClearScanProc,size={100,20}
End

//Procedures for Set Scan button - generates scan bounds based on checked boxes
Function SetScanProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SetDatafolder root:ExpParams
	WAVE LoadedWave
	switch( ba.eventCode )	
		case 2: // mouse up
			
			ClearScanBounds()
			GenerateBounds(LoadedWave,DefaultSettings())
			KillControl/W=Pulse Run
			ControlInfo SaveSettings
			Button Run win=Pulse,pos={575,V_top}, title="Run", proc=RunProc,size={100,20}
			break
		case -1:
			break
	endswitch
	
End

//Proceudres for Clear Scan - Clears scan bounds
Function ClearScanProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )	
		case 2: // mouse up
			ClearScanControls()
			PopupMenu Sequence popmatch=" ", win=Pulse
			
			KillControl/W=Pulse Loops
			KillControl/W=Pulse SetScan
			KillControl/W=Pulse ClearScan
			KillControl/W=Pulse Run
			MoveWindow/W=Pulse 0,0,333,100
			break
		case -1:
			break
	endswitch
End

//Procedures for Load Settings Button - loads the scan bounds and checkboxes from file
Function LoadSettingsProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SetDataFolder root:ExpParams
	WAVE ScanParams
	WAVE LoadedWave
	WAVE wave0
	
	switch(ba.eventCode)
		case 2: //mouse up

			GenerateScanControls(LoadedWave,LoadScanSettings())
			GenerateBounds(LoadedWave,wave0)
			CreateButtons()
			KillControl/W=Pulse Run
			ControlInfo SaveSettings
			Button Run win=Pulse,pos={575,V_top}, title="Run", proc=RunProc,size={100,20}
			break
		case -1:
			break
	endswitch
End

Function/WAVE LoadScanSettings()
	SetDataFolder root:ExpParams	
	WAVE wave0

	Variable SequenceNum
	ControlInfo Sequence
	SequenceNum=V_Value-1
	
		
		String Loadwavestring="LoadWave/O/D/H/J/M/N/G/P=SettingsSavePath1"
		Execute Loadwavestring
	Return wave0
End

//Procedures for Save Settings Button - Saves current scan bounds and checkboxes
Function SaveSettingsProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SetDataFolder root:ExpParams
	NVAR SettingsCheckOut
	switch(ba.eventCode)
		case 2: //mouse up
			DoWindow/K SaveWaveWindow
//			GetScanOrder()
			GetScanParams()
			If(SettingsCheck()==0)
				Execute "SaveSettingsWindow()"			
			Endif
			break
		case -1:
			
			break
	endswitch
End


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

Window SaveSettingsWindow() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1/W=(806,108,1138,208) as "Save Settings as..."
	SetVariable SequenceNamefield pos={100,17.5},size={195,20},BodyWidth=185,title="Settings Name:",value=_STR:"SettingsName"
	Button WaveSaveButton pos={197.5,57.5},size={100,20},title="Save Sequence",proc=SaveButtonProc
EndMacro

Function SaveButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	WAVE ScanParams
	Variable SequenceNum
	ControlInfo/W=Pulse Sequence
	 SequenceNum=V_Value
	String SettingName
	switch(ba.eventCode)
		case 2: //mouse up
			ControlInfo/W=SaveSettingsWindow SequenceNamefield
			SettingName=S_Value
			String SaveSettingsstring="Save/P=SettingsSavePath"+num2str(SequenceNum-1)+"/O/G/W ScanParams as \""+SettingName+".dat\""
			Execute SaveSettingsString
			DoAlert/T="Save Message" 0, "Settings Saved"
			DoWindow/K SaveSettingsWindow
			break
		case -1:
			
			break
	endswitch
End

//Procedures for Run button - checks to make sure info is input correctly, then sends sequence to the fpga
Function RunProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR SendCounter
	switch( ba.eventCode )	
		case 2: // mouse up
			GetScanParams()
			SendCounter=0
			
			If (SettingsCheck()==0)
				DefineValuesLooper()
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

//Checks to make sure the Scan Order doesn't skip a number
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

Function TestPrint(loader)
	WAVE loader
	SetDataFolder root:ExpParams
	Variable i,ii,iii
	
	For (i=0;i<FindTotalStep();i+=1)
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

//Loads scan parameters or set points into Wave
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



Function/WAVE DefaultSettings()
	Make/O/N=(5*1024,6) settin
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
		Else
			settin[7*i][1]=1
			settin[7*i][2]=1
			settin[7*i][3]=5
			settin[7*i][4]=1
		Endif
		
	EndFor
	
	Return settin
End

//Finds AND RETURNS the total number of steps in the loaded wave
Function FindTotalStep()
	SetDataFolder root:ExpParams
	WAVE LoadedWave
	Variable TotalStep=0
	Variable i=0
	Do
		If(LoadedWave[i][1]!=0)
			TotalStep+=1
		Else
			Break
		Endif
		i+=1
	While(i<1024)
	Return TotalStep
End

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

//Finds AND RETURNS Total number of steps to send to FPGA
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

//Finds AND RETURNS total number of groups
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
//Finds AND RETURNS the position of a given scan number  in the scanparams wave
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

//finds AND RETURNS the size of the group number passed to the function
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

//Need to finish writing this function
//need to find value scanned over and write values accordingly
//Do by conditional name==1,2,3
	//then if name==1,2,3 check if dds value scanned
		//write accordingly
Function DefineValuesLooper()
	SetDataFolder root:ExpParams
	WAVE ScanParams
	WAVE LoadedWave
	Make/O/N=(3,4) DDSWAVE
	MAKE/O/N=(FindTotalStep(),2) VALWAVE
	Variable ScanCount=1
	Variable i
	Variable ii
	Variable Incrementer
	ScanCount=0
	If (FindTotalScan()>0)
		Do
		Incrementer=0
		ii=0
		i=0
		GetScanParams()
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
								SendtoFPGA(DefineValues(i,ii,incrementer),GrabDDSValues(-1,-1,-1))//step number, substep, increment number//tells function to grab the setpoints for the DDS//sends to FPGA
							//	Print("Sent to SendtoFPGA: ")
							//	TestPrintVALS(DefineValues(i,ii,incrementer))
							//TestPrintDDS(GrabDDSValues(-1,-1,-1))						
							Else
						
								SendtoFPGA(DefineValues(-1,-1,-1),GrabDDSValues(i,ii,incrementer))//Tells function to grab setpoints//step number, substep, imcrement number
							Endif
							incrementer+=1
						While (ScanParams[7*i+ii][4]*incrementer<=ScanParams[7*i+ii][3]-ScanParams[7*i+ii][2])
					Elseif(LoadedWave[i][0]==2||LoadedWave[i][0]==3)
						ii=1
						Do 
							If (ScanParams[7*i+ii][5]==ScanCount+1)
								Break
							Endif
							ii+=1
						While (ii<7)
						Do
							If (ii==1)
								SendtoFPGA(DefineValues(i,ii,incrementer),GrabDDSValues(-1,-1,-1))//step number, substep, increment number//tells function to grab the setpoints for the DDS//sends to FPGA
							//	Print("Sent to SendtoFPGA: ")
							//	TestPrintVALS(DefineValues(i,ii,incrementer))
							//TestPrintDDS(GrabDDSValues(-1,-1,-1))						
							Else
						
								SendtoFPGA(DefineValues(-1,-1,-1),GrabDDSValues(i,ii,incrementer))//Tells function to grab setpoints//step number, substep, imcrement number
							Endif
							incrementer+=1
						While (ScanParams[7*i+ii][4]*incrementer<=ScanParams[7*i+ii][3]-ScanParams[7*i+ii][2])
					Else
						Do
						
							SendtoFPGA(DefineValues(i,0,incrementer),GrabDDSValues(-1,-1,-1))
							incrementer+=1
						While (ScanParams[7*i][4]*incrementer<ScanParams[7*i][3]-ScanParams[7*i][2])
					Endif
				Endif
			Endfor
			ScanCount+=1
		While (ScanCount<FindTotalScan())
	Else
		SendtoFPGA(DefineValues(-1,-1,-1),GrabDDSValues(-1,-1,-1))
	Endif
	
End

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
			Print(i)
				For (ii=0;ii<3;ii+=1)
					ReturnWave[i-1][ii+1]=DDSSetPoints[ii][i-1]
				Endfor
			Endif
			i+=1
		While (i<=3)
	Endif
	Return ReturnWave
End

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

Function SendtoFPGA(valuewave,ddsvaluewave)
	WAVE valuewave
	WAVE ddsvaluewave
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
//
//	Do
//		SetDDS(i+1,ddsvaluewave[i][0],ddsvaluewave[i][1],ddsvaluewave[i][2])
//		i+=1
//	While(i<3)

//	Print("****************")
//	TestPrintFinal(WavetoFPGA)
//	PRint("%%%%%%%%")
//	TestPrintVALS(valuewave)
	//TestPrintDDS(ddsvaluewave)
	If(SendCounter==0)
		Print("Sending to FPGA....")
	Else
		For(i=0;i<SendCounter;i+=1)
		LoadingScreen+="..."
		Print(LoadingScreen)
		EndFor
	Endif
	
	If(SendCounter<10)
		SendCounter+=1
	Else
		SendCounter=0
	Endif
	
	SendSequence(WavetoFPGA)
	
	ControlInfo Loops
	loopmultiplier=V_Value

	runSequence(loopmultiplier, recmask = 0xFF)

	//Alternatively, can use a do function to take data after each run:
//	i=0
//	Do
//		runSequence(1)
//		TakeData()
//		i+=1
//	While (i<loopmultiplier)
	
	
	
	
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

Function StopTTL()
	Variable ttlnumber
	
	Make/D/O/N=(1,2) turnoff
	
	String turnttloff = "turnoff={{0x000000},{0x1000000}}"
	Execute turnttloff
	
	sendSequence(turnoff)
	runSequence(1)
	
End