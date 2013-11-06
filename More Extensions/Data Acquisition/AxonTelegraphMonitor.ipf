#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion=6.1	// Control panel features and named background tasks.
#pragma Version=1.0
#pragma IndependentModule=AxonTelegraphPanel

// REVISION HISTORY
// Version		Description
// 1.0			Initial release
//


// Igor structure that should be used with the AxonTelegraphGetDataStruct() external function.
Structure AxonTelegraph_DataStruct
	uint32 Version			// Structure version.  Value should always be 13.
	uint32 SerialNum
	uint32 ChannelID
	uint32 ComPortID
	uint32 AxoBusID
	uint32 OperatingMode
	String OperatingModeString
	uint32 ScaledOutSignal
	String ScaledOutSignalString
	double Alpha
	double ScaleFactor
	uint32 ScaleFactorUnits
	String ScaleFactorUnitsString
	double LPFCutoff
	double MembraneCap
	double ExtCmdSens
	uint32 RawOutSignal
	String RawOutSignalString
	double RawScaleFactor
	uint32 RawScaleFactorUnits
	String RawScaleFactorUnitsString
	uint32 HardwareType
	String HardwareTypeString
	double SecondaryAlpha
	double SecondaryLPFCutoff
	double SeriesResistance
EndStructure

Constant kTelegraphDataStructVersion = 13
Constant kBackgroundTaskPeriod = 30

StrConstant kAxonTelegraphPanelName = "pnlAxonTelegraphPanel"
StrConstant kAxonTelegraphPanelDF = "root:AxonTelegraphPanel"

Menu "Misc", hideable
	"Axon Telegraph Data", /Q, AxonTelegraphDataPanel()
end

///////////////////////////////////////////////////////////////
// INITIALIZATION AND PANEL BUILDING
///////////////////////////////////////////////////////////////
//**
// Initializes globals and builds the panel.
//*
Function AxonTelegraphDataPanel()
	DoWindow/F $(kAxonTelegraphPanelName)
	if (V_Flag)
		return 0
	endif
	Initialize()
	DoAxonTelegraphDataPanel()
	SetStartStopButtonTitle()
	NVAR currentChannelID = $(kAxonTelegraphPanelDF + ":currentChannelID")
	NVAR currentSerialNum = $(kAxonTelegraphPanelDF + ":currentSerialNum")
	if (numtype(currentSerialNum) != 0 || numtype(currentChannelID) != 0)
		// Disable button until a serial and channel have been selected.
		SetStartStopButtonDisable(1)
	else
		SetStartStopButtonDisable(0)
	endif
		
	ControlUpdate/W=$(kAxonTelegraphPanelName) button_startstop
End

//**
// Initializes all global variables for the panel.
//*
Function Initialize()
	String currentDF = GetDataFolder(1)
	NewDataFolder/O/S $(kAxonTelegraphPanelDF)
	
	// Variables
	Variable/G panelInitialized = 1
	Variable/G timeoutMs = AxonTelegraphGetTimeoutMs()
	if (!exists("currentSerialNum"))
		Variable/G currentSerialNum = NaN
	endif
	
	if (!exists("currentChannelID"))
		Variable/G currentChannelID = NaN
	endif

	if (!exists("currentComPortID"))
		Variable/G currentComPortID = NaN
	endif
	
	if (!exists("currentAxoBusID"))
		Variable/G currentAxoBusID = NaN
	endif	
				
	if (!exists("currentlyMonitoring"))
		Variable/G currentlyMonitoring =  0
	endif
	
	if (!exists("V_Flagsss"))
		Variable/G V_Flag = 0
	endif
	
	if (!exists("getLongStrings"))
		Variable/G getLongStrings = 1
	endif
	
	// Data variables
	String globalVarList
	globalVarList = "OperatingMode;ScaledOutSignal;Alpha;ScaleFactor;ScaleFactorUnits;LPFCutoff;"
	globalVarList += "MembraneCap;ExtCmdSens;RawOutSignal;RawScaleFactor;RawScaleFactorUnits;"
	globalVarList += "HardwareType;SecondaryAlpha;SecondaryLPFCutoff;SeriesResistance;"
	String currentGlobalVarName
	Variable n, numGlobalVars = ItemsInList(globalVarList, ";")
	For (n=0; n<numGlobalVars; n+=1)
		currentGlobalVarName = StringFromList(n, globalVarList, ";")
		if (!exists(currentGlobalVarName))
			Variable/G $(currentGlobalVarName) = 0
		endif
	EndFor
	
	// Strings
	if (!exists("serverList"))
		String/G serverList = "Click the \"Find servers\" button and then select a server"
	endif
	
	// Data strings
	String globalStringList
	globalStringList = "OperatingMode;ScaledOutSignal;ScaleFactorUnits;RawOutSignal;RawScaleFactorUnits;HardwareType;"
	String currentGlobalStringName
	Variable numGlobalStrings = ItemsInList(globalStringList, ";")
	For (n=0; n<numGlobalStrings; n+=1)
		currentGlobalStringName = StringFromList(n, globalStringList, ";")
		if (!exists(currentGlobalStringName + "_str"))
			String/G $(currentGlobalStringName + "_str") = ""
		endif
	EndFor
	
	SetDataFolder currentDF
End

//**
// Code that creates the data panel.  This is in a function
// since this is part of an independent module.
//*
Function DoAxonTelegraphDataPanel()
	NewPanel /W=(76,62,538,642)/N=$(kAxonTelegraphPanelName)/K=1 as "MultiClamp Telegraph Data"
	ModifyPanel fixedSize=1		// Set to 1 to allow panel to be resized
	GroupBox group_serverInfo,pos={6,5},size={446,345},title="\\f01Telegraph Server Information"
	GroupBox group_serverInfo,fSize=18,frame=0
	ValDisplay valdisp_gain_primary,pos={31,202},size={100,17},bodyWidth=60,title="\\f01Gain:"
	ValDisplay valdisp_gain_primary,fSize=14,frame=0
	ValDisplay valdisp_gain_primary,valueBackColor=(61440,61440,61440)
	ValDisplay valdisp_gain_primary,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_gain_primary,value= #kAxonTelegraphPanelDF+":Alpha"
	GroupBox group_primary_output,pos={13,179},size={425,50},title="\\f01Primary Output:\\f00\tAuxiliary 2 (88.850 V/V)"
	GroupBox group_primary_output,fSize=14
	GroupBox group_secondary_output,pos={13,253},size={425,50},title="\\f01Secondary Output:\\f00\tAuxiliary 2 (3.850 V/V)"
	GroupBox group_secondary_output,fSize=14
	ValDisplay valdisp_lpfcutoff_primary,pos={168,202},size={131,17},bodyWidth=75,title="\\f01Bessel:"
	ValDisplay valdisp_lpfcutoff_primary,userdata=  "%.2W1PHz",fSize=14
	ValDisplay valdisp_lpfcutoff_primary,format="%.2W1PHz",frame=0
	ValDisplay valdisp_lpfcutoff_primary,valueBackColor=(61440,61440,61440)
	ValDisplay valdisp_lpfcutoff_primary,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_lpfcutoff_primary,value= #kAxonTelegraphPanelDF+":LPFCutoff"
	ValDisplay valdisp_gain_secondary,pos={31,276},size={100,17},bodyWidth=60,title="\\f01Gain:"
	ValDisplay valdisp_gain_secondary,fSize=14,frame=0
	ValDisplay valdisp_gain_secondary,valueBackColor=(61440,61440,61440)
	ValDisplay valdisp_gain_secondary,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_gain_secondary,value= #kAxonTelegraphPanelDF+":SecondaryAlpha"
	ValDisplay valdisp_lpfcutoff_secondary,pos={168,276},size={131,17},bodyWidth=75,title="\\f01Bessel:"
	ValDisplay valdisp_lpfcutoff_secondary,userdata=  "%.2W1PHz",fSize=14
	ValDisplay valdisp_lpfcutoff_secondary,format="%.2W1PHz",frame=0
	ValDisplay valdisp_lpfcutoff_secondary,valueBackColor=(61440,61440,61440)
	ValDisplay valdisp_lpfcutoff_secondary,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_lpfcutoff_secondary,value= #kAxonTelegraphPanelDF+":SecondaryLPFCutoff"
	GroupBox group_wholecell,pos={252,89},size={186,72},title="\\f01Whole cell parameters"
	GroupBox group_wholecell,fSize=14
	ValDisplay valdisp_Rs,pos={273,112},size={125,19},bodyWidth=100,disable=2,title="\\f01R\\Bs\\M:"
	ValDisplay valdisp_Rs,fSize=14,format="%.3W1POhm",frame=0
	ValDisplay valdisp_Rs,fColor=(47872,47872,47872),valueColor=(47872,47872,47872)
	ValDisplay valdisp_Rs,valueBackColor=(61440,61440,61440)
	ValDisplay valdisp_Rs,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_Rs,value= #kAxonTelegraphPanelDF+":SeriesResistance"
	ValDisplay valdisp_cap,pos={273,134},size={127,19},bodyWidth=100,title="\\f01C\\Bm\\M:"
	ValDisplay valdisp_cap,fSize=14,format="%.3W1PF",frame=0
	ValDisplay valdisp_cap,valueBackColor=(61440,61440,61440)
	ValDisplay valdisp_cap,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp_cap,value= #kAxonTelegraphPanelDF+":MembraneCap"
	Button button_startstop,pos={13,315},size={150,25},proc=Button_start_stop_monitoring,title="Start monitoring"
	Button button_startstop,fSize=14
	SetVariable setvar_setTimeout,pos={13,412},size={164,20},bodyWidth=70,proc=SetVar_TimeoutMs,title="\\f01Timeout (ms)"
	SetVariable setvar_setTimeout,fSize=14
	SetVariable setvar_setTimeout,limits={0,15000,100},value= $(kAxonTelegraphPanelDF+":timeoutMs")
	PopupMenu popup_selectserver,pos={13,65},size={401,21},bodyWidth=300,proc=PopMenu_SelectServer,title="\\f01Select server:"
	PopupMenu popup_selectserver,fSize=14
	PopupMenu popup_selectserver,mode=1,value= #kAxonTelegraphPanelDF+":serverlist"
	Button button_scan,pos={13,35},size={110,25},proc=Button_scanServers,title="Find servers"
	Button button_scan,fSize=14
	SetVariable setvar_mode,pos={13,118},size={219,20},bodyWidth=100,title="\\f01Operating mode:"
	SetVariable setvar_mode,fSize=14,frame=0,valueBackColor=(61440,61440,61440)
	SetVariable setvar_mode,limits={-1,1,0},value= $(kAxonTelegraphPanelDF+":OperatingMode_str"),noedit= 1
	SetVariable setvar_hardwaretype,pos={13,89},size={229,20},bodyWidth=120,title="\\f01Hardware type:"
	SetVariable setvar_hardwaretype,fSize=14,frame=0
	SetVariable setvar_hardwaretype,valueBackColor=(61440,61440,61440)
	SetVariable setvar_hardwaretype,limits={-1,1,0},value= $(kAxonTelegraphPanelDF+":HardwareType_str"),noedit= 1
	GroupBox group_timeout,pos={6,374},size={446,70},title="\\f01Timeout",fSize=18
	GroupBox group_timeout,frame=0
	GroupBox group_errormessage,pos={6,470},size={446,100},disable=2,title="\\f01Error message"
	GroupBox group_errormessage,fSize=18,frame=0
	NewNotebook /F=1 /N=NBERROR /W=(6,494,452,569) /HOST=# /OPTS=15 
	Notebook kwTopWin, defaultTab=36, statusWidth=0, autoSave= 1, writeProtect=1, backRGB=(61440,61440,61440), showRuler=0, rulerUnits=1
	Notebook kwTopWin newRuler=Normal, justification=0, margins={0,0,324}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",10,0,(0,0,0)}
	Notebook kwTopWin, zdata= "GaqDU%ejN7!Z)u^\"(F_BAcgu:*j$\"_6ioh?E[<\\YCht`&)]4ZMgifPM3#6'PjtHc8d0L&b"
	Notebook kwTopWin, zdataEnd= 1
	RenameWindow #,NBERROR
	SetActiveSubwindow ##
	SetWindow kwTopWin hook(AxonTelegraphPanel)=AxonTelegraphMonitor_Hook
EndMacro

///////////////////////////////////////////////////////////////
// BACKGROUND TASK RELATED
///////////////////////////////////////////////////////////////
//**
// Start or stop the background task that monitors the amplifier telegraphs.
//*
Function Control_monitoring()
	NVAR/Z monitoring = $(kAxonTelegraphPanelDF+":currentlyMonitoring")
	CtrlNamedBackground axonTelegraph status
	Variable run = NumberByKey("RUN", S_info , ":", ";")
	if (!NVAR_Exists(monitoring))
		Initialize()
		NVAR/Z monitoring = $(kAxonTelegraphPanelDF+":currentlyMonitoring")
	endif
		
	if (monitoring)
		if (numtype(run) != 0 || run == 0)
			String cmd
			sprintf cmd, "CtrlNamedBackground axonTelegraph, burst=0, dialogsOK=1, period=%d, proc=%s#Background_monitoring, start", kBackgroundTaskPeriod, GetIndependentModuleName()
			Execute cmd
		endif
	else
		if (run == 1)
			CtrlNamedBackground axonTelegraph, stop=1
		endif
	endif
End

//**
// Background task that Igor calls each time the background task should run.
//*
Function Background_monitoring(s)
	STRUCT WMBackgroundStruct &s
	Variable start = StopMsTimer(-2)
	NVAR/Z monitoring = $(kAxonTelegraphPanelDF+":currentlyMonitoring")
	if (NVAR_Exists(monitoring) && monitoring)
		UpdateAllData()
	endif
//	printf "Background task took %f ms.\r", (StopMsTimer(-2) - start) / 1000
	return 0		// Continue background task.
End

//////////////////////////////////////////////////////////
// UTILITY FUNCTIONS
//////////////////////////////////////////////////////////
//**
// Clear the error message in the notebook subwindow and disable the
// group box containing the subwindow.
//*
Function ClearErrorMessage()
	// Make sure panel is displayed.
	DoWindow $(kAxonTelegraphPanelName)
	if (!V_Flag)
		return 0
	endif
	
	ControlInfo/W=$(kAxonTelegraphPanelName) group_errormessage
	if (V_disable != 2)
		GroupBox group_errormessage win=$(kAxonTelegraphPanelName), disable=2
	endif
	Notebook $(kAxonTelegraphPanelName)#NBERROR selection={startOfFile, endOfFile}, text="", backRGB = (61440, 61440, 61440)
End

//**
// Set an error message in the notebook subwindow and alert
// the user by beeping.
//
// @param messageStr
// 	A string containing the error message that should be displayed
// 	in the notebook subwindow.
//*
Function SetErrorMessage(messageStr)
	String messageStr
	// Make sure panel is displayed.
	DoWindow $(kAxonTelegraphPanelName)
	if (!V_Flag)
		return 0
	endif
	
	ControlInfo/W=$(kAxonTelegraphPanelName) group_errormessage
	if (V_disable != 0)
		GroupBox group_errormessage win=$(kAxonTelegraphPanelName), disable=0
		beep
	endif
	Notebook $(kAxonTelegraphPanelName)#NBERROR selection={startOfFile, endOfFile}, fSize=12, text=messageStr, backRGB = (65535, 65535, 65535)
End

//**
// Utility function that updates the titles of the primary and secondary
// output GroupBoxes based on the primary and secondary output
// parameters being measured.
//*
Function UpdatePanelGroupTitles()
	// Make sure panel is displayed
	DoWindow $(kAxonTelegraphPanelName)
	if (!V_Flag)
		return 0
	endif
	String currentDF = GetDataFolder(1)
	SetDataFolder $(kAxonTelegraphPanelDF)
		
	NVAR OperatingMode,ScaledOutSignal,Alpha,ScaleFactor,ScaleFactorUnits,LPFCutoff
	NVAR MembraneCap,ExtCmdSens,RawOutSignal,RawScaleFactor,RawScaleFactorUnits
	NVAR HardwareType,SecondaryAlpha,SecondaryLPFCutoff,SeriesResistance

	SVAR OperatingMode_str, ScaledOutSignal_str, ScaleFactorUnits_str, RawOutSignal_str, RawScaleFactorUnits_str, HardwareType_str
	
	String primaryOutput = ""
	String secondaryOutput = ""
	
	sprintf primaryOutput, "\f01Primary Output:\f00\t%s (%.3f %s)", ScaledOutSignal_str, ScaleFactor * Alpha, ScaleFactorUnits_str
	sprintf secondaryOutput, "\f01Secondary Output:\f00\t%s (%.3f %s)", RawOutSignal_str, RawScaleFactor * SecondaryAlpha, RawScaleFactorUnits_str
	
	// Set titles (but only if the title would change, to prevent annoying blinking of the controls).
	ControlInfo/W=$(kAxonTelegraphPanelName) group_primary_output
	if (cmpstr(S_value, primaryOutput) != 0)
		GroupBox group_primary_output,win=$(kAxonTelegraphPanelName),title=primaryOutput
	endif

	ControlInfo/W=$(kAxonTelegraphPanelName) group_secondary_output
	if (cmpstr(S_value, secondaryOutput) != 0)
		GroupBox group_secondary_output,win=$(kAxonTelegraphPanelName),title=secondaryOutput
	endif


	SetDataFolder currentDF
End

//**
// Simple utility function that in turn calls
// functions to get telegraph data and update
// all of the controls on the panel that need to be
// updated when new data comes in.
//*
Function UpdateAllData()
		GetAxonDataUsingStruct()
		UpdatePanelGroupTitles()
		ProcessAxonData()
End

//**
// Utility function that updates the titles of group boxes and the
// format string of the filter frequency setvar controls depending
// on the values of some of the amplifier settings.
//*
Function ProcessAxonData()
	// Make sure panel is displayed.
	DoWindow $(kAxonTelegraphPanelName)
	if (!V_Flag)
		return 0
	endif
	String currentDF = GetDataFolder(1)
	SetDataFolder $(kAxonTelegraphPanelDF)
		
	NVAR OperatingMode,ScaledOutSignal,Alpha,ScaleFactor,ScaleFactorUnits,LPFCutoff
	NVAR MembraneCap,ExtCmdSens,RawOutSignal,RawScaleFactor,RawScaleFactorUnits
	NVAR HardwareType,SecondaryAlpha,SecondaryLPFCutoff,SeriesResistance

	SVAR OperatingMode_str, ScaledOutSignal_str, ScaleFactorUnits_str, RawOutSignal_str, RawScaleFactorUnits_str, HardwareType_str
	
	// Disable Rs control if value is 0.  Note that setting disable doesn't do anything, so
	// instead we change the font color.  However we also set disable because it's easy
	// to check whether or not a control is disabled using ControlInfo.  Only update the
	// control's properties if they need to be changed.
	ControlInfo/W=$(kAxonTelegraphPanelName) valdisp_Rs
	if (SeriesResistance == 0)
		if (V_disable != 2)
			ValDisplay valdisp_Rs win=$(kAxonTelegraphPanelName),valueColor=(47872,47872,47872), fColor=(47872,47872,47872), disable=2
		endif			
	elseif (V_disable != 0)
		ValDisplay valdisp_Rs win=$(kAxonTelegraphPanelName),valueColor=(0, 0, 0), fColor=(0, 0, 0), disable=0
	endif

	// Disable Cp control if value is 0.  Note that setting disable doesn't do anything, so
	// instead we change the font color.  However we also set disable because it's easy
	// to check whether or not a control is disabled using ControlInfo.  Only update the
	// control's properties if they need to be changed.
	ControlInfo/W=$(kAxonTelegraphPanelName) valdisp_cap
	if (MembraneCap == 0)
		if (V_disable != 2)
			ValDisplay valdisp_cap win=$(kAxonTelegraphPanelName),valueColor=(47872,47872,47872), fColor=(47872,47872,47872), disable=2
		endif
	elseif (V_disable != 0)
		ValDisplay valdisp_cap win=$(kAxonTelegraphPanelName),valueColor=(0, 0, 0), fColor=(0, 0, 0), disable=0
	endif
	
	// Disable Whole cell parameters group box if both Rs and Cm are 0.  Note that setting disable doesn't do anything, so
	// instead we change the font color.  However we also set disable because it's easy
	// to check whether or not a control is disabled using ControlInfo.  Only update the
	// control's properties if they need to be changed.
	ControlInfo/W=$(kAxonTelegraphPanelName) group_wholecell
	if (MembraneCap == 0 && SeriesResistance == 0)
		if (V_disable != 2)
			GroupBox group_wholecell win=$(kAxonTelegraphPanelName),disable=2
		endif
	elseif (V_disable != 0)
		GroupBox group_wholecell win=$(kAxonTelegraphPanelName),disable=0
	endif
	
	SetDataFolder currentDF
	
	// Print "Bypass" instead of filter frequency setting when frequency is 1.0e5
	// (which according to Axon means it's in bypass).  Only do this if the new format
	// string, which we store in the control's unnamed userdata, is different than what is already there.
	String filterFrequencyFormatStr = ""
	if (LPFCutoff == 1.0e5)
		filterFrequencyFormatStr = "Bypass"
	else
		filterFrequencyFormatStr = "%.2W1PHz"
	endif
	ControlInfo/W=$(kAxonTelegraphPanelName) valdisp_lpfcutoff_primary
	if (cmpstr(S_UserData, filterFrequencyFormatStr) != 0)
		ValDisplay valdisp_lpfcutoff_primary win=$(kAxonTelegraphPanelName),format= filterFrequencyFormatStr, userdata=filterFrequencyFormatStr
	endif
	
	if (SecondaryLPFCutoff == 1.0e5)
		filterFrequencyFormatStr = "Bypass"
	else
		filterFrequencyFormatStr = "%.2W1PHz"
	endif
	ControlInfo/W=$(kAxonTelegraphPanelName) valdisp_lpfcutoff_secondary
	if (cmpstr(S_UserData, filterFrequencyFormatStr) != 0)
		ValDisplay valdisp_lpfcutoff_secondary win=$(kAxonTelegraphPanelName),format= filterFrequencyFormatStr, userdata=filterFrequencyFormatStr
	endif
End

//**
// Utility function to set the title of the start/stop button
// to the correct value depending on whether or not
// the amplifier is currently being monitored.
//*
Function SetStartStopButtonTitle()
	DoWindow $(kAxonTelegraphPanelName)
	if (V_flag == 0)
		return 0
	endif
	
	NVAR/Z monitoring = $(kAxonTelegraphPanelDF+":currentlyMonitoring")
	if (!NVAR_Exists(monitoring))
		Initialize()
		NVAR/Z monitoring = $(kAxonTelegraphPanelDF+":currentlyMonitoring")
		if (!NVAR_Exists(monitoring))
			return 0
		endif
	endif
	String buttonTitle
	if (monitoring)
		buttonTitle = "Stop monitoring"
	else
		buttonTitle = "Start monitoring"
	endif
	Button button_startstop, win=$(kAxonTelegraphPanelName), title=buttonTitle
	ControlUpdate/A/W=$(kAxonTelegraphPanelName)
End

//**
// Set the disable status of the start/stop button.
// @param isDisabled
// 	1 if the button should be disabled or 0 if it should be enabled.
//*
Function SetStartStopButtonDisable(isDisabled)
	Variable isDisabled
	
	DoWindow $(kAxonTelegraphPanelName)
	if (V_flag == 0)
		return 0
	endif
	Variable disable = isDisabled? 2 : 0
	Button button_startstop, win=$(kAxonTelegraphPanelName), disable=disable
End

//**
// Utility function that finds all available telegraph
// servers and stores the list in a global string.
//*
Function ScanForServers()
	String currentDF = GetDataFolder(1)
	SetDataFolder $(kAxonTelegraphPanelDF)
	
	NVAR timeout = $(kAxonTelegraphPanelDF + ":timeoutMs")
	AxonTelegraphFindServers
	WAVE telegraphServersWave = W_TelegraphServers
	
	SVAR serverList
	serverList = ""
	Variable n, numServers = DimSize(telegraphServersWave, 0)
	String currentServerDesc
	For (n=0; n<numServers; n+=1)
		// Note:  If the format string below is changed it must also be changed in PopMenu_SelectServer().
		if (telegraphServersWave[n][0] < 0)
			// Server is a 700A server.
			sprintf currentServerDesc, "%s: ComPort: %d   AxoBus ID: %d   Channel ID: %d", "700A", telegraphServersWave[n][%ComPortID],  telegraphServersWave[n][%AxoBusID], telegraphServersWave[n][%ChannelID]
		else
			// Server is a 700B server.
			sprintf currentServerDesc, "%s:  Serial number: %d    Channel ID: %d", "700B", telegraphServersWave[n][%SerialNum], telegraphServersWave[n][%ChannelID]
		endif
		serverList = AddListItem(currentServerDesc, serverList, ";", inf)
	EndFor
	SetDataFolder currentDF
	
End



//**
// Utility function that gets all parameters from the currently selected
// telegraph server and stores all values into global variables and strings.
//*
Function GetAxonDataUsingStruct()
	String currentDF = GetDataFolder(1)
	SetDataFolder $(kAxonTelegraphPanelDF)
	
	// Get all string values for the currently selected server.
	NVAR/Z serialNum = currentSerialNum
	NVAR/Z channelID = currentChannelID
	NVAR/Z comPortID = currentComPortID
	NVAR/Z axoBusID = currentAxoBusID
	
	if (!NVAR_Exists(serialNum) || !NVAR_Exists(channelID) || !NVAR_Exists(comPortID) || !NVAR_Exists(axoBusID))
		SetDataFolder currentDF
		return 0
	elseif (numtype(serialNum) != 0 || numtype(channelID) != 0 || numtype(comPortID) != 0 || numtype(axoBusID) != 0)
		SetDataFolder currentDF
		return 0
	endif
	
	NVAR/Z getLongStrings = getLongStrings
	if (!NVAR_Exists(getLongStrings) || numtype(getLongStrings) != 0)
		Variable/G getLongStrings = 1
		NVAR getLongStrings = getLongStrings
	endif
	
	try
		STRUCT AxonTelegraph_DataStruct tds
		tds.version = kTelegraphDataStructVersion
		if (serialNum < 0)
			// We're using a 700A
			AxonTelegraphAGetDataStruct(comPortID, axoBusID, channelID, getLongStrings, tds);AbortOnRTE
		else
			// We're using a 700B
			AxonTelegraphGetDataStruct(serialNum, channelID, getLongStrings, tds);AbortOnRTE
		endif
		
		ClearErrorMessage()
		NVAR OperatingMode,ScaledOutSignal,Alpha,ScaleFactor,ScaleFactorUnits,LPFCutoff
		NVAR MembraneCap,ExtCmdSens,RawOutSignal,RawScaleFactor,RawScaleFactorUnits
		NVAR HardwareType,SecondaryAlpha,SecondaryLPFCutoff,SeriesResistance
	
		SVAR OperatingMode_str, ScaledOutSignal_str, ScaleFactorUnits_str, RawOutSignal_str, RawScaleFactorUnits_str, HardwareType_str
		
		// Copy data from structure into global variables.
		OperatingMode = tds.OperatingMode
		OperatingMode_str = tds.OperatingModeString
		ScaledOutSignal = tds.ScaledOutSignal
		ScaledOutSignal_str = tds.ScaledOutSignalString
		Alpha = tds.Alpha
		ScaleFactor = tds.ScaleFactor
		ScaleFactorUnits = tds.ScaleFactorUnits
		ScaleFactorUnits_str = tds.ScaleFactorUnitsString
		LPFCutoff = tds.LPFCutoff
		MembraneCap = tds.MembraneCap
		ExtCmdSens = tds.ExtCmdSens
		RawOutSignal = tds.RawOutSignal
		RawOutSignal_str = tds.RawOutSignalString
		RawScaleFactor = tds.RawScaleFactor
		RawScaleFactorUnits = tds.RawScaleFactorUnits
		RawScaleFactorUnits_str = tds.RawScaleFactorUnitsString
		HardwareType = tds.HardwareType
		HardwareType_str = tds.HardwareTypeString
		SecondaryAlpha = tds.SecondaryAlpha
		SecondaryLPFCutoff = tds.SecondaryLPFCutoff
		SeriesResistance = tds.SeriesResistance
	catch
		String errorMessage = GetRTErrMessage()
		Variable value
		value = GetRTError(1)
		SetErrorMessage(StringFromList(1, errorMessage, ";"))
	endtry
	SetDataFolder currentDF	
End

//////////////////////////////////////////////////////////
// CONTROL ACTION PROCEDURES
//////////////////////////////////////////////////////////
//**
// Action procedure for Select server popup menu control
// that sets global variables indicating which server
// should be monitored.
//*
Function PopMenu_SelectServer(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			NVAR currentChannelID = $(kAxonTelegraphPanelDF+":currentChannelID")
			NVAR currentSerialNum = $(kAxonTelegraphPanelDF+":currentSerialNum")
			NVAR currentComPortID = $(kAxonTelegraphPanelDF+":currentComPortID")
			NVAR currentAxoBusID = $(kAxonTelegraphPanelDF+":currentAxoBusID")			
			Variable channel, serial, comPort, axoBus
			sscanf popStr, "700B:  Serial number: %d    Channel ID: %d", serial, channel
			if (V_flag == 2)
				// The selected item represents a 700B server.
				currentChannelID = channel
				currentSerialNum = serial
				currentComPortID = -1
				currentAxoBusID = -1
				UpdateAllData()
				SetStartStopButtonDisable(0)
			else
				// The selected item must represent a 700A server.
				sscanf popStr, "700A: ComPort: %d  AxoBus ID: %d  Channel ID: %d", comPort, axoBus, channel
				if (V_flag == 3)
					// The selected item represents a 700B server.
					currentChannelID = channel
					currentSerialNum = -1
					currentComPortID = comPort
					currentAxoBusID = axoBus
					UpdateAllData()
					SetStartStopButtonDisable(0)
				endif
			endif
			break
	endswitch

	return 0
End

//**
// Action procedure for start/stop button that starts or stops monitoring.
//*
Function Button_start_stop_monitoring(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NVAR/Z monitoring = $(kAxonTelegraphPanelDF+":currentlyMonitoring")
			if (NVAR_Exists(monitoring))
				monitoring = !monitoring
				SetStartStopButtonTitle()
				Control_monitoring()
			endif
			break
	endswitch

	return 0
End

//**
// Action procedure for timout setvar which calls the XOP
// to set the timeout value and then calls the XOP again
// to read the new timeout value.
//*
Function SetVar_TimeoutMs(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			try
				NVAR timeoutMs = $(kAxonTelegraphPanelDF + ":timeoutMs")
				AxonTelegraphSetTimeoutMs(timeoutMs);AbortOnRTE
				ClearErrorMessage()
				// Read back value from XOP to make sure it was set properly.
				timeoutMs = AxonTelegraphGetTimeoutMs();AbortOnRTE
			catch
				String errorMessage = GetRTErrMessage()
				Variable value
				value = GetRTError(1)
				SetErrorMessage(StringFromList(1, errorMessage, ";"))
			endtry
						
			break
	endswitch

	return 0
End

//**
// Action procedure for "Find servers" button.
//*
Function Button_scanServers(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ScanForServers()
			break
	endswitch

	return 0
End

//**
// Panel window hook function.
//*
Function AxonTelegraphMonitor_Hook(s)
	STRUCT WMWinHookStruct &s
	
	Switch (s.eventCode)
		Case 2:		// Window is being killed.
			NVAR/Z monitoring = $(kAxonTelegraphPanelDF+":currentlyMonitoring")
			if (NVAR_Exists(monitoring))
				monitoring = !monitoring
				SetStartStopButtonTitle()
				Control_monitoring()
			endif
			break
	EndSwitch
	return 0
End