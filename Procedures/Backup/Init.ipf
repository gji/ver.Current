#pragma rtGlobals=1		// Use modern global access method.

//_____________________________________________________________________________
//
// Exp_Init() is a macro that initializes all of the global variables and creates the control panels.
//_____________________________________________________________________________
//
Macro Exp_Init()

	DefaultGUIFont/Win all={"Arial",12,0},panel={"Arial",12,3}

	Param_Init()
	Seq_init()
	DC_Init()
	//MMCInit
	
	// Kill all control panels if they exist
	doWindow/HIDE=? OverrideVariables
	If(V_FLag)
		KillWindow OverrideVariables
	Endif
	doWindow/HIDE=? PulseCreator
	If(V_FLag)
		KillWindow PulseCreator
	Endif
	doWindow/HIDE=? Pulse
	If(V_FLag)
		KillWindow Pulse
	Endif
	doWindow/HIDE=? DCCtrlPanel
	If(V_FLag)
		KillWindow DCCtrlPanel
	Endif
		doWindow/HIDE=? DataLoader
	If(V_FLag)
		KillWindow DataLoader
	If(V_FLag)
		KillWindow PTS control
	Endif
		doWindow/HIDE=? PTS control
	Endif
	
	// Creates Windows	
	
	PulseCreator()	// For Creating Pulse Sequences
	Pulse()			// For Running Pulse Sequence
	DCCtrl() 			// For Setting DC Bias on Trap
	OverrideVariables()
EndMacro

//_____________________________________________________________________________
//
// Param_Init() sets global variables and initializes hardware
//_____________________________________________________________________________
//
Function Param_Init()

	NewDataFolder/O/S root:PMT
	Variable/G PMT_BUFFER = 68
	Make/B/U/O/N=(PMT_BUFFER) PMTcounts
	
	NewDataFolder/O/S root:ExpParams
	
	String/G ScanControlRecreator = ""		// Saves command that recreate the experimental scan control
	Variable/G CARRIER_FREQ = 247		// Carrier frequency in MHz
	Variable/G SHUTTLE_DURATION = 100	// Total shuttling duration assuming constant shuttling time
	
	String/G SEQ_NAME 					= "Sequencer"
	String/G DDS_NAME 					= "DDS"
	String/G PMT_NAME 					= "PMT_FPGA"
	String/G TDC_NAME 					= "TDC_FPGA"
	String/G SEQ_PORT 					= "COM14"
	String/G DDS_PORT 					= "COM11"
	String/G PMT_PORT 					= "COM20"
	String/G TDC_PORT 					= ""

	// Discover available COM ports. Sometimes the first query returns a strange character, 
	// so repeat just in case.
	VDTGetPortListDescription2
	SVAR S_VDT
	String ports = S_VDT
	VDTGetPortListDescription2
	ports = S_VDT
	
	// 2014/02/28 : There is a problem with the 64-bit compiled VDT2.xop that causes
	// VDTGetPortListDescription2 to fail most of the time. It probably has to do with the 
	// character conversion hack done by Geoffrey Ji when he had to modify the 
	// VDT2.xop for the 32-bit version. Currently COM ports are assigned manually until
	// this bug is fixed.
	
	// Parse the VDTGetPortListDescription2 return string for COM port numbers
	Variable n= ItemsInList(ports)
	Make/O/T/N=(n) devices = StringFromList(p,ports)
	Variable t;
	for(t=0; t<n; t+=1)
		String device = devices[t] 
		if(strsearch(device, SEQ_NAME,0) != -1)
			SEQ_PORT = device[(strsearch(device,",",0)+1),strlen(device)]
			printf "Sequencer port: %s\r" SEQ_PORT
			VDT2/P=$SEQ_PORT baud=230400,stopbits=2,killio
		endif
		if(strsearch(device, DDS_NAME,0) != -1)
			DDS_PORT = device[(strsearch(device,",",0)+1),strlen(device)]
			printf "DDS port: %s\r" DDS_PORT
			VDT2/P=$DDS_PORT baud=230400,stopbits=2,killio
		endif
		if(strsearch(device, PMT_NAME,0) != -1)
			PMT_PORT = device[(strsearch(device,",",0)+1),strlen(device)]
			printf "PMT array port: %s\r" PMT_PORT
			VDT2/P=$PMT_PORT baud=115200,stopbits=1,killio
		endif
		if(strsearch(device, TDC_NAME,0) != -1)
			TDC_PORT = device[(strsearch(device,",",0)+1),strlen(device)]
			printf "TDC port: %s\r" TDC_PORT
			VDT2/P=$TDC_PORT baud=230400,stopbits=2,killio
		endif
	endfor
	
	Variable/G LIVE_UP					= 	0			// Sets live update state for DC voltage control
	Variable/G CUR_POS					= 	LOAD_POS		
		
	Variable/G DELAY						=	TTL_00	
	Variable/G COOL						=	TTL_04
	Variable/G REPUMP					=	TTL_03
	Variable/G STATE_DET				=	TTL_01|DI_01
	Variable/G FLR_DET					=	TTL_04|TTL_02|DI_01
	Variable/G PUMP						=	TTL_01|TTL_05
	Variable/G LOAD_SHTR				=	TTL_08
	Variable/G MICROWAVE				=	TTL_06
	Variable/G PMT						=	DI_01	// PMT might be gated, might need to add a TTL pulse here
	
	Variable/G COOL_FREQ				= 	290 // MHz
	Variable/G COOL_AMP					=	100 // Max Amp
	Variable/G COOL_PHASE				=	0 	
	
	Variable/G PUMP_FREQ				= 	300 // MHz
	Variable/G PUMP_AMP					=	100 // Max Amp
	Variable/G PUMP_PHASE				=	0 	
	
	Variable/G STATE_DET_FREQ			=	220 // MHz
	Variable/G STATE_DET_AMP			=	100 // Max Amp
	Variable/G STATE_DET_PHASE		=	0	
	
	Variable/G FLR_DET_FREQ			=	220 // MHz
	Variable/G FLR_DET_AMP				=	100 // Max Amp
	Variable/G FLR_DET_PHASE			=	0

	Variable/G MIN_POSITION = 0			// Lowest ion position index (voltage set specification)
	Variable/G MAX_POSITION = 10		// Highest ion position index (voltage set specification)
	Variable/G DEFAULT_POSITION = 0	// Default ion position index (voltage set specification)


	String/G	WAVEb_compRF				=	""
	String/G	WAVEb_Quad45				=	":waveforms:GenIII:GenIII_Uniform_Quad45.csv"
	String/G	WAVEb_Ez					=	":waveforms:GenIII:GenIII_Ez_LV.csv"
	String/G	WAVEb_Ex					=	":waveforms:GenIII:GenIII_Ex_LV.csv"
	String/G	WAVEb_Ey					=	":waveforms:GenIII:GenIII_Ey_LV.csv"
	String/G	WAVEb_Harm				=	":waveforms:GenIII:GenIII_Harmonic.csv"		
	String/G	WAVEb_Hardware			=	":waveforms:GenIII:GenIII_hardware.csv"
	
	String/G	WAVEc_compRF				=	""
	String/G	WAVEc_Quad45				=	":waveforms:GenIII:GenIII_Uniform_Quad45.csv"
	String/G	WAVEc_Ez					=	""
	String/G	WAVEc_Ex					=	""
	String/G	WAVEc_Ey					=	":waveforms:GenIII:GenIII_Uniform_Ey.csv"
	String/G	WAVEc_Harm				=	":waveforms:GenIII:genIII_chain_10ions.csv"		
	String/G	WAVEc_Hardware			=	":waveforms:GenIII:GenIII_hardware.csv"
	
	String/G	WAVEa_compRF				=	""
	String/G	WAVEa_Quad45				=	":waveforms:BGA:BGA_20140502_Quad45.csv"
	String/G	WAVEa_Ez					=	":waveforms:BGA:BGA_20140502_compEz.csv"
	String/G	WAVEa_Ex					=	":waveforms:BGA:BGA_20140502_uniform_compEx.csv"
	String/G	WAVEa_Ey					=	":waveforms:BGA:BGA_20140502_uniform_compEy.csv"
	String/G	WAVEa_Harm				=	":waveforms:BGA:BGA_20140502_harmonic.csv"		
	String/G	WAVEa_Hardware			=	":waveforms:BGA:Hardware_BGA.csv"


	//Variables for Pulse Program
	NewDataFolder/O root:DataAnalysis
	
	Make/O/N=0 GroupVals
	Make/O/N=0 PopupVals
	
	Variable/G SequenceCurrent                       =  0
	Variable/G VerticalButtonPosition                =  16
	Variable/G VerticalLoopPosition                  =  16
	Variable/G GroupNumber                           =  0
	Variable/G GroupError                            =  0
	Make/D/O/N=8 NameWave                              =  {DELAY,COOL,STATE_DET,FLR_DET,PUMP,LOAD_SHTR,PMT,MICROWAVE}
	Make/O/T/N=8 TTLNames                            =  {"Delay","Cool", "State Detection","Flourescence Detection","Pump", "LoadShutter","PMT","Microwave"}
	// The following should be matched up, in order, with TTLNames. The indexes denote the scan types labeled in SCAN_TITLES.
	// For example, 0 is for Delay, 0123 is for Cooling. 
	String/G 	 TTL_PARAMS			                   	=	"0;012345;0123;012345;012345;0;0;0;"
	String/G	 SCAN_TITLES 				             = "Duration;AO Frequency;AO Amplitude;AO Phase;EO Frequency;EO Power;Rotation Amplitude;Rotation Frequency;Rotation Phase"
	Make/O/T/N=3 DDSNames                         	=	{"State Detection","Flourescence Detection", "Doppler Cooling"}
	Make/O/T/N=4 DDSScans									=	{"Duration","Frequency","Amplitude","Phase"}
	Make/O/T/N=3 EONames									=	{"Optical Pumping", "Cooling", "Repump"}
	Make/O/T/N=1 EONotDDSNames							=	{"935 EO"}
	Make/O/T/N=3 EONOTDDSSCans							=	{"Duration","EO Frequency","EO Amplitude"}
	Make/O/T/N=6 EOScans									=	{"Duration","AO Frequency","AO Amplitude","AO Phase","EO Frequency","EO Amplitude"}
	Make/O/N=(1024,3)	PulseCreatorWave					=	0
	Make/O/N=(1024,3) dataloaderwave						=	0
	Variable/G TooLong										=	0

	PathInfo home				// Save home folder of unpacked experiment folder to S_path
	String homeFolder = S_path	// Save path to persistent local variable
	NewPath/O/C/Q/Z SequencesPath, homeFolder+"Sequences:"
	NewPath/O/C/Q/Z SettingsPath, homeFolder+"Settings:"
	NewPath/O/C/Q/Z DataPath, homeFolder+"Data:"

	Variable/G TotalScan									=	0
	Variable/G FixScanOrder								=	0
	Variable/G GroupMultiplier							=	1
	Make/O/N=(1024,2) PulseSequence
	Make/O/N=1024 TimeSequence
	Variable/G DDS1Counter,DDS2Counter,DDS3Counter	=	0
	Variable/G DDS7Counter,DDS8Counter,DDSCounted		=	0
	Variable/G DDS10Counter							 	=	0
	Make/O/N=(5120,6) Settings							=	0
	Variable/G SettingsCheckOut							=	0
	Make/O/N=(3,4) DDSsetPoints							=	{{COOL_FREQ,COOL_PHASE,COOL_AMP},{STATE_DET_FREQ,STATE_DET_PHASE,STATE_DET_AMP},{FLR_DET_FREQ,FLR_DET_PHASE,FLR_DET_AMP}}
	Make/O/N=(2,3) EOSetPoints							=	{{1,2105,100},{2,7374,100}}
	Variable/G SendCounter									=	0
	Make/O/N=(7*1024,6) ScanParams=0
	String/G LoadingScreen
	String/G Test1
	String/G Test2
	String/G Test3
	String/G Test4
	Variable/G DDSnum										=	3
	Variable/G EOnum											=	3

	Make/O/N=(8,3) OverrideWave							=	0
	Make/O/N=(3,4) EO_INFO									=	{{0,1,2},{2105,7374,3060},{100,100,100},{0,0,0}}	
	Variable/G Mask											=	0
	
	
	Make/O/N=0/T SavedSequences
	Make/O/N=0/T LoadWaveFiles
	
	// Grab all sequences in the folder
	Variable fileIndex = 0

	do
		String fileName
		fileName = IndexedFile(SequencesPath, fileIndex, "????")
		if (strlen(fileName) == 0)
			break
		endif
		InsertPoints 0,1,LoadWaveFiles
		LoadWaveFiles[0] = fileName
		fileIndex += 1
	while(1)
	
	Variable/G TDC											=0

	Make/O/N=(DDS_Channels,DDS_Params+1) 	DDS_INFO
	Make/O/N=7 							COMP_INFO		 = {0.02,-0.36,0.23,0.0,0,.4,1}
	Make/O/T/N=7 						WAVE_INFOa	 = {WAVEa_Ex, WAVEa_Ey, WAVEa_Quad45, WAVEa_Ez, WAVEa_compRF, WAVEa_Harm, WAVEa_Hardware}
	Make/O/T/N=7 						WAVE_INFOb	 = {WAVEb_Ex, WAVEb_Ey, WAVEb_Quad45, WAVEb_Ez, WAVEb_compRF, WAVEb_Harm, WAVEb_Hardware}
	Make/O/T/N=7 						WAVE_INFOc	 = {WAVEc_Ex, WAVEc_Ey, WAVEc_Quad45, WAVEc_Ez, WAVEc_compRF, WAVEc_Harm, WAVEc_Hardware}
	Duplicate/O WAVE_INFOa, WAVE_INFO
	
	Variable j,i
	for(i=0;i!=(DDS_Channels); i+=1)
		switch(i)
			case COOL_CNL:
				For(j=0; j!=(DDS_Params+1); j+=1)	
					switch(j)
						case 0:		
							DDS_INFO[i][j]	=	COOL_FREQ
							break
						case 1:
							DDS_INFO[i][j]	=	COOL_AMP
							break
						case 2:
							DDS_INFO[i][j]	=	COOL_PHASE
							break
						default:
							DDS_INFO[i][j]	=	0
					EndSwitch
				EndFor
				break
			case STATE_DET_CNL:
				For(j=0; j!=(DDS_Params+1); j+=1)	
					switch(j)
						case 0:	
							DDS_INFO[i][j]	=	STATE_DET_FREQ	
							break
						case 1:
							DDS_INFO[i][j]	=	STATE_DET_AMP
							break
						case 2:
							DDS_INFO[i][j]	=	STATE_DET_PHASE
							break
						default:
							DDS_INFO[i][j]	=	0
					EndSwitch
				EndFor
				break
			case FLR_DET_CNL:
				For(j=0; j!=(DDS_Params+1); j+=1)	
					switch(j)
						case 0:	
							DDS_INFO[i][j]	=	FLR_DET_FREQ
							break
						case 1:
							DDS_INFO[i][j]	=	FLR_DET_AMP
							break
						case 2:
							DDS_INFO[i][j]	=	FLR_DET_PHASE
							break
						default:
							DDS_INFO[i][j]	=	0
					EndSwitch
				EndFor
				break			
			default:
				For(j=0; j!=(DDS_Params+1); j+=1)	
					switch(j)
						default:
							DDS_INFO[i][j]	=	0
					EndSwitch
				EndFor
		EndSwitch
	Endfor	
End


//_____________________________________________________________________________
//
// DC_init() initializes the NI DAC boards
//_____________________________________________________________________________
//
Function DC_init()
	NewDataFolder/O/S root:DCVolt
	NewDataFolder/O/S root:DCVolt:temp
	LoadDCWaveMatrices()
	updateVoltages()
End

//_____________________________________________________________________________
//
// LoadDCWaveMatrices() loads all voltage matrices
//_____________________________________________________________________________
//
Function LoadDCWaveMatrices()
	SetDataFolder root:DCVolt
	
	WAVE COMP_INFO			=	root:ExpParams:COMP_INFO
	WAVE/T WAVE_INFO		=	root:ExpParams:WAVE_INFO
	
	// Store the hardware map in ExpParams
	SetDataFolder root:ExpParams
	LoadWave/M/K=2/U={0,0,1,0}/O/B="N=HARDWARE_MAP;" /J/P=home WAVE_INFO[6]
	SetDataFolder root:DCVolt
	WAVE/T HARDWARE_MAP	=	root:ExpParams:HARDWARE_MAP
	
	Variable i,j,k,m=0;
	for(i=0;i<DimSize(HARDWARE_MAP,0);i+=1)
		if(!stringmatch(HARDWARE_MAP[i][2],"")) 
			m+=1
		endif
	endfor
	
	Variable/G NUM_ELECT 	= m;
	NVAR CUR_POS				= root:ExpParams:CUR_POS
	
	Make/O/N=(NUM_ELECT,6)	FIELDS
	Make/O/N=(NUM_ELECT) RAW_VOLTAGES
	Make/O/N=96  OUT_VOLTAGES
	Make/T/O/N=12 CMDS	
	
	for(i=0; i<6; i+=1) // There are 6 possible waveforms
		SetDataFolder root:DCVolt:temp
		if(StringMatch(WAVE_INFO[i],""))
			Wave t = $("root:DCVolt:mat"+num2str(i))
			print "Skipping voltage file " + num2str(i)
			KillWaves t
			continue
		endif
		WAVE t = LoadDCWaveMatrixHelper(WAVE_INFO[i], num2str(i)) // Grab each waveform into temp matrix
		Make/O/N=(DimSize(t,0),NUM_ELECT+1) ::$("mat"+num2str(i)) // Make actual matrix. Extra row for indicies
		WAVE out = ::$("mat"+num2str(i)) // Get a wave reference to the just-created wave
		// Put ion positions into actual matrix, fill rest with 0's
		for(k=0; k<DimSize(t,0);k+=1)
			out[k][0] = t[k][0]
			for(j=1;j<NUM_ELECT+1;j+=1)
				out[k][j]=0	
			endfor
		endfor
		// Do actual copying of voltages, referencing the hardware map
		for(j=1; j<DimSize(t,1);j+=1)
			FindValue/TEXT=GetDimLabel(t,1,j) HARDWARE_MAP // Look for electrode, stores into V_Value
			// pos = HARDWARE_MAP[V_value][0]
			if(V_Value <= -1)
				continue
			endif
			do
				Variable col, row
				col=floor(V_value/DimSize(HARDWARE_MAP, 0))
				row=V_value-col*DimSize(HARDWARE_MAP, 0)
				for(k=0; k<DimSize(t,0);k+=1)
					out[k][row+1] = t[k][j]
				endfor
				FindValue/S=(V_value+1)/TEXT=GetDimLabel(t,1,j) HARDWARE_MAP
			while (V_value > -1)
		endfor
		SetDataFolder root:DCVolt		
		print "There are " + num2str(NUM_ELECT) + " electrodes."		
		Wave tmat = $("mat" + num2str(i))
		FindValue/V=(CUR_POS) tmat
		FIELDS[][i] = tmat[V_Value][p+1]
	endfor		
End

//_____________________________________________________________________________
//
//
//_____________________________________________________________________________
//
Function/WAVE LoadDCWaveMatrixHelper(filename, outname) //Loads single voltage matrix
	String filename
	String outname
	
	NewDataFolder/O/S root:DCVolt:temp
	
	String matname = "matWave" + outname
	LoadWave/M/O/U={0,0,1,0}/B="N=" + matname + ";" /J/P=home filename
	
	return $matname
EndMacro

//_____________________________________________________________________________
//
//
//_____________________________________________________________________________
//

Function PulseCreator_Init(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	 Switch (ba.eventCode)
	 	Case 2: //mouse up
	 		string windows= WinList("PulseCreator"," ; ","")
			if	(strlen(windows)>0)
			else
				Execute "PulseCreator()"
			endif
	 		Break
		Case -1: // control being killed
			Break
	 EndSwitch

	Return 0
End


//_____________________________________________________________________________
//
//
//_____________________________________________________________________________
//

Function Pulse_Init(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	 Switch (ba.eventCode)
	 	Case 2: //mouse up
	 		string windows= WinList("Pulse"," ; ","")
			if	(strlen(windows)>0)
			else
				Execute "Pulse()"
			endif
	 		Break
		Case -1: // control being killed
			Break
	 EndSwitch

	Return 0
End


//_____________________________________________________________________________
//
//
//_____________________________________________________________________________
//

Function DC_ctrl_Init(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	 Switch (ba.eventCode)
	 	Case 2: //mouse up
	 		string windows= WinList("DCCtrl"," ; ","")
			if	(strlen(windows)>0)
			else
				Execute "DCCtrl()"
			endif
	 		Break
		Case -1: // control being killed
			Break
	 EndSwitch

	Return 0
End
//_____________________________________________________________________________
//
//
//_____________________________________________________________________________
//

Function DataFrameInit(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	 Switch (ba.eventCode)
	 	Case 2: //mouse up
	 		DataDisplay()
	 		Break
		Case -1: // control being killed
			Break
	 EndSwitch

	Return 0
End
//_____________________________________________________________________________
//
//
//_____________________________________________________________________________
//

Function SeqInit(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	 Switch (ba.eventCode)
	 	Case 2: //mouse up
	 		Seq_Init()
	 		Break
		Case -1: // control being killed
			Break
	 EndSwitch

	Return 0
End
//_____________________________________________________________________________
//
//
//_____________________________________________________________________________
//
Function Seq_init()
	NewDataFolder/O/S root:DDS	
	NewDataFolder/O/S root:Sequencer
	SetDataFolder root:Sequencer	
	NewDataFolder/O/S :Data
	
	Make/O PulseProgram
	Make/B/U/O/n=0 WriteWave
	Make/O/N=50 dataScanVar =	0
	
	String/G ScanVarName = ""
	
	string name
	variable i=0
	
	SetDataFolder root:Sequencer:Data
	For(i=1;i!=9;i+=1)
		name="dataStd_0"+num2str(i)
		if(exists(name))
		else
			Make/O/N=50 $name
		endif
		name="data_0"+num2str(i)
		if(exists(name))
		else
			Make/O/N=50 $name
		endif
		name="dataAvg_0"+num2str(i)
		if(exists(name))
		else
			Make/O/N=50 $name
		endif
		name="dataHist_0"+num2str(i)
		if(exists(name))
		else
			Make/O/N=50 $name
		endif
		name="dataProb_0"+num2str(i)
		if(exists(name))
		else
			Make/O/N=50 $name
		endif
		name="dataBiErr_0"+num2str(i)
		if(exists(name))
		else
			Make/O/N=50 $name
		endif
	endfor

End

//_____________________________________________________________________________
//
//
//_____________________________________________________________________________
//
Function PTS_init()

	String coolPTSaddress		= "GPIB0::16::INSTR"
	String pumpPTSaddress		= "GPIB0::8::INSTR"
	String detectPTSaddress		= "GPIB0::3::INSTR"
	Variable coolPTSamplitude 	= 1
	Variable pumpPTSamplitude	= 1
	Variable detectPTSamplitude	= 1
	Variable coolPTSfrequency 	= 2900000000
	Variable pumpPTSfrequency	= 3000000000
	Variable detectPTSfrequency	= 3000000000

End

//_____________________________________________________________________________
//
// Create DC control panel
//_____________________________________________________________________________
//
Window DCCtrl() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(1189,997,1449,1373) as "Trap DC Voltage Control"
	ModifyPanel cbRGB=(48896,59904,65280)
	SetVariable apos,pos={43,17},size={77,18},bodyWidth=60,proc=fieldUpdate,title="Ex"
	SetVariable apos,limits={-inf,inf,0.01},value= root:ExpParams:COMP_INFO[0]
	SetVariable bpos,pos={43,47},size={77,18},bodyWidth=60,proc=fieldUpdate,title="Ey"
	SetVariable bpos,limits={-inf,inf,0.01},value= root:ExpParams:COMP_INFO[1]
	SetVariable cpos,pos={42,77},size={78,18},bodyWidth=60,proc=fieldUpdate,title="45"
	SetVariable cpos,limits={-inf,inf,0.01},value= root:ExpParams:COMP_INFO[2]
	SetVariable dpos,pos={43,107},size={77,18},bodyWidth=60,proc=fieldUpdate,title="Ez"
	SetVariable dpos,limits={-inf,inf,0.01},value= root:ExpParams:COMP_INFO[3]
	SetVariable epos,pos={40,137},size={80,18},bodyWidth=60,proc=fieldUpdate,title="RF"
	SetVariable epos,limits={-inf,inf,0.01},value= root:ExpParams:COMP_INFO[4]
	SetVariable harmScale,pos={4,167},size={116,18},bodyWidth=60,proc=fieldUpdate,title="Harm. SF"
	SetVariable harmScale,limits={-inf,inf,0.01},value= root:ExpParams:COMP_INFO[5]
	SetVariable globScale,pos={9,197},size={111,18},bodyWidth=60,proc=fieldUpdate,title="Glob. SF"
	SetVariable globScale,limits={-inf,inf,0.01},value= root:ExpParams:COMP_INFO[6]
	SetVariable posIon,pos={11,227},size={109,18},bodyWidth=60,proc=fieldUpdate,title="Ion Pos."
	SetVariable posIon,limits={-440,inf,1},value= root:ExpParams:CUR_POS
	Button update,pos={135,255},size={110,20},proc=Update,title="Update"
	Button settings,pos={135,285},size={110,20},proc=openSettings,title="Settings"
	CheckBox liveupdate,pos={39,258},size={83,15},proc=LiveUpCheck,title="Live Update"
	CheckBox liveupdate,value= 0,side= 1
EndMacro

Window DCSettings() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(1464,996,1839,1260) as "DC Voltage Settings"
	ModifyPanel cbRGB=(48896,49152,65280)
	SetVariable afile,pos={16,17},size={279,18},bodyWidth=185,title="A Voltage File Ex"
	SetVariable afile,value= root:ExpParams:WAVE_INFO[0]
	SetVariable bfile,pos={15,47},size={280,18},bodyWidth=185,title="B Voltage File Ey"
	SetVariable bfile,value= root:ExpParams:WAVE_INFO[1]
	SetVariable cfile,pos={13,77},size={282,18},bodyWidth=185,title="C Voltage File 45"
	SetVariable cfile,value= root:ExpParams:WAVE_INFO[2]
	SetVariable dfile,pos={14,107},size={281,18},bodyWidth=185,title="D Voltage File Ez"
	SetVariable dfile,value= root:ExpParams:WAVE_INFO[3]
	SetVariable efile,pos={12,137},size={283,18},bodyWidth=185,title="E Voltage File RF"
	SetVariable efile,value= root:ExpParams:WAVE_INFO[4]
	SetVariable hfile,pos={5,167},size={290,18},bodyWidth=185,title="Harm. Voltage File"
	SetVariable hfile,value= root:ExpParams:WAVE_INFO[5]
	SetVariable wfile,pos={3,197},size={292,18},bodyWidth=185,title="Hardware Map File"
	SetVariable wfile,value= root:ExpParams:WAVE_INFO[6]
	Button aopen,pos={300,15},size={50,20},proc=OpenWaveFile,title="Open"
	Button bopen,pos={300,45},size={50,20},proc=OpenWaveFile,title="Open"
	Button copen,pos={300,75},size={50,20},proc=OpenWaveFile,title="Open"
	Button dopen,pos={300,105},size={50,20},proc=OpenWaveFile,title="Open"
	Button eopen,pos={300,135},size={50,20},proc=OpenWaveFile,title="Open"
	Button hopen,pos={300,165},size={50,20},proc=OpenWaveFile,title="Open"
	Button wopen,pos={300,195},size={50,20},proc=OpenWaveFile,title="Open"
	Button updateFields,pos={137,225},size={135,20},proc=OpenWaveFile,title="Update Field Waves"
	CheckBox abank,pos={285,228},size={25,15},proc=DCBankProc,title="A"
	CheckBox abank,value= 1,mode=1
	CheckBox bbank,pos={315,228},size={26,15},proc=DCBankProc,title="B"
	CheckBox bbank,value= 0,mode=1
	CheckBox cbank,pos={345,228},size={27,15},proc=DCBankProc,title="C"
	CheckBox cbank,value= 0,mode=1
EndMacro
//_____________________________________________________________________________
//
// Create DDS control panel
//_____________________________________________________________________________
//
//Window DDS_Control() : Panel
//	SetDataFolder root:DDS
//	PauseUpdate; Silent 1		// building window...
//	NewPanel /K=1 /W=(30+0,75+298,30+260,75+298+170) as "DDS_Control"
//	ModifyPanel cbRGB=(65534,65534,65534)
//	SetVariable DDS1_FREQ_BOX,pos={50,15},size={195,20},bodyWidth=130,proc=DDS_wrapper,title="DDS1 Frequency"
//	SetVariable DDS1_FREQ_BOX,font="Arial"
//	SetVariable DDS1_FREQ_BOX,limits={0,400,1},value= root:ExpParams:DDS_INFO[0][0]
//	SetVariable DDS2_FREQ_BOX,pos={50,35},size={195,20},bodyWidth=130,proc=DDS_wrapper,title="DDS2 Frequency"
//	SetVariable DDS2_FREQ_BOX,font="Arial"
//	SetVariable DDS2_FREQ_BOX,limits={0,400,1},value= root:ExpParams:DDS_INFO[1][0]
//	SetVariable DDS1_PHASE_BOX,pos={50,65},size={195,20},bodyWidth=130,proc=DDS_wrapper,title="DDS1 Amplitude"
//	SetVariable DDS1_PHASE_BOX,font="Arial"
//	SetVariable DDS1_PHASE_BOX,limits={0,180,1},value= root:ExpParams:DDS_INFO[0][1]
//	SetVariable DDS2_PHASE_BOX,pos={50,85},size={195,20},bodyWidth=130,proc=DDS_wrapper,title="DDS2 Amplitude"
//	SetVariable DDS2_PHASE_BOX,font="Arial"
//	SetVariable DDS2_PHASE_BOX,limits={0,180,1},value= root:ExpParams:DDS_INFO[1][1]
//	SetVariable DDS1_AMPL_BOX,pos={50,115},size={195,20},bodyWidth=130,proc=DDS_wrapper,title="DDS1 Phase"
//	SetVariable DDS1_AMPL_BOX,font="Arial"
//	SetVariable DDS1_AMPL_BOX,limits={0,1023,1},value= root:ExpParams:DDS_INFO[0][2]
//	SetVariable DDS2_AMPL_BOX,pos={50,135},size={195,20},bodyWidth=130,proc=DDS_wrapper,title="DDS2 Phase"
//	SetVariable DDS2_AMPL_BOX,font="Arial"
//	SetVariable DDS2_AMPL_BOX,limits={0,1023,1},value= root:ExpParams:DDS_INFO[1][2]
//EndMacro

//_____________________________________________________________________________
//
// Create experimental sequence control panel
//_____________________________________________________________________________
//
Window Pulse() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(1890,1346,2757,1725) as "Pulse Program"
	ModifyPanel cbRGB=(48896,65280,57344)
	PopupMenu Sequence,pos={61,18},size={209,21},bodyWidth=150,proc=PopMenuProc,title="Sequence"
	PopupMenu Sequence,mode=6,popvalue="PMTTEST",value= #"makepopnames()"
	TitleBox Step0Title,pos={15,65},size={150,20},title="Cool"
	TitleBox Step0Title,labelBack=(65535,65535,65535),frame=5,anchor= MC,fixedSize=1
	SetVariable Step0position,pos={261,67},size={79,18},bodyWidth=30,title="Position"
	SetVariable Step0position,limits={0,10,1},value= _NUM:0
	CheckBox Step0Scan0,pos={170,67},size={65,15},proc=ConstructScanControls,title="Duration"
	CheckBox Step0Scan0,userdata=  "Cool;Duration;",value= 0
	SetVariable Step0setpoint0,pos={369,67},size={101,18},bodyWidth=50,title="Duration"
	SetVariable Step0setpoint0,limits={10,1e+08,0.5},value= _NUM:10
	CheckBox Step0Scan1,pos={170,92},size={73,15},disable=2,proc=ConstructScanControls,title="Amplitude"
	CheckBox Step0Scan1,userdata=  "Cool;Amplitude;",value= 0
	SetVariable Step0setpoint1,pos={361,92},size={109,18},bodyWidth=50,title="Amplitude"
	SetVariable Step0setpoint1,limits={0,1023,1},value= _NUM:1023
	CheckBox Step0Scan2,pos={170,117},size={75,15},proc=ConstructScanControls,title="Frequency"
	CheckBox Step0Scan2,userdata=  "Cool;Frequency;",value= 0
	SetVariable Step0setpoint2,pos={359,117},size={111,18},bodyWidth=50,title="Frequency"
	SetVariable Step0setpoint2,limits={100,400,0.01},value= _NUM:200
	TitleBox Step1Title,pos={15,140},size={150,20},title="Flourescence Detect"
	TitleBox Step1Title,labelBack=(65535,65535,65535),frame=5,anchor= MC,fixedSize=1
	SetVariable Step1position,pos={261,142},size={79,18},bodyWidth=30,title="Position"
	SetVariable Step1position,limits={0,10,1},value= _NUM:0
	CheckBox Step1Scan0,pos={170,142},size={65,15},proc=ConstructScanControls,title="Duration"
	CheckBox Step1Scan0,userdata=  "Flourescence Detect;Duration;",value= 1
	SetVariable Step1setpoint0,pos={369,142},size={101,18},bodyWidth=50,title="Duration"
	SetVariable Step1setpoint0,limits={10,1e+08,0.5},value= _NUM:1000000
	CheckBox Step1Scan1,pos={170,167},size={73,15},disable=2,proc=ConstructScanControls,title="Amplitude"
	CheckBox Step1Scan1,userdata=  "Flourescence Detect;Amplitude;",value= 0
	SetVariable Step1setpoint1,pos={361,167},size={109,18},bodyWidth=50,title="Amplitude"
	SetVariable Step1setpoint1,limits={0,1023,1},value= _NUM:1023
	CheckBox Step1Scan2,pos={170,192},size={75,15},proc=ConstructScanControls,title="Frequency"
	CheckBox Step1Scan2,userdata=  "Flourescence Detect;Frequency;",value= 0
	SetVariable Step1setpoint2,pos={359,192},size={111,18},bodyWidth=50,title="Frequency"
	SetVariable Step1setpoint2,limits={100,400,0.01},value= _NUM:200
	TitleBox Step2Title,pos={15,215},size={150,20},title="Cool"
	TitleBox Step2Title,labelBack=(65535,65535,65535),frame=5,anchor= MC,fixedSize=1
	SetVariable Step2position,pos={261,217},size={79,18},bodyWidth=30,title="Position"
	SetVariable Step2position,limits={0,10,1},value= _NUM:0
	CheckBox Step2Scan0,pos={170,217},size={65,15},proc=ConstructScanControls,title="Duration"
	CheckBox Step2Scan0,userdata=  "Cool;Duration;",value= 0
	SetVariable Step2setpoint0,pos={369,217},size={101,18},bodyWidth=50,title="Duration"
	SetVariable Step2setpoint0,limits={10,1e+08,0.5},value= _NUM:10
	CheckBox Step2Scan1,pos={170,242},size={73,15},disable=2,proc=ConstructScanControls,title="Amplitude"
	CheckBox Step2Scan1,userdata=  "Cool;Amplitude;",value= 0
	SetVariable Step2setpoint1,pos={361,242},size={109,18},bodyWidth=50,title="Amplitude"
	SetVariable Step2setpoint1,limits={0,1023,1},value= _NUM:1023
	CheckBox Step2Scan2,pos={170,267},size={75,15},proc=ConstructScanControls,title="Frequency"
	CheckBox Step2Scan2,userdata=  "Cool;Frequency;",value= 0
	SetVariable Step2setpoint2,pos={359,267},size={111,18},bodyWidth=50,title="Frequency"
	SetVariable Step2setpoint2,limits={100,400,0.01},value= _NUM:200
	SetVariable Loops,pos={542,290},size={150,18},title="Data Point Loop"
	SetVariable Loops,limits={0,65535,1},value= _NUM:100
	SetVariable Times,pos={700,290},size={150,18},title="Experimental Loop"
	SetVariable Times,limits={0,65536,1},value= _NUM:1
	Button SaveSettings,pos={15,320},size={100,20},proc=SaveSettingsProc,title="Save Settings"
	PopupMenu LoadSettings,pos={173,320},size={184,21},bodyWidth=150,proc=LoadSettingsPopMenuProc,title="Load:"
	PopupMenu LoadSettings,mode=1,value= #"LoadSettingsList()"
	Button Run,pos={575,320},size={100,20},proc=RunProc,title="Run"
	CheckBox TDCbox,pos={683,320},size={76,15},title="TDC on/off"
	CheckBox TDCbox,variable= root:ExpParams:TDC
	SetVariable Step1Scan0Min,pos={527,142},size={73,18},bodyWidth=50,title="Min"
	SetVariable Step1Scan0Min,limits={10,1e+08,0.5},value= _NUM:500000
	SetVariable Step1Scan0Max,pos={625,142},size={75,18},bodyWidth=50,title="Max"
	SetVariable Step1Scan0Max,limits={10,1e+08,0.5},value= _NUM:5000000
	SetVariable Step1Scan0Inc,pos={730,142},size={70,18},bodyWidth=50,title="Inc"
	SetVariable Step1Scan0Inc,limits={0.5,1e+08,0.5},value= _NUM:500000
	Button DataFrame,pos={14,344},size={100,20},proc=DataFrameInit,title="Data Frame Init"
	SetWindow kwTopWin,hook(scroll)=ScrollHook
EndMacro

//_____________________________________________________________________________
//
// makepopnames() scans the stored sequences folder to populate the drop-down menu
//_____________________________________________________________________________
//
Function/S makepopnames()

	NewDataFolder/O/S root:Sequences
	Variable numSavedSequences = CountObjects("", 1)
	//print numSavedSequences
	//WAVE/T SavedSequences = root:ExpParams:SavedSequences
	String names = " "
	Variable idx
	for (idx = 0; idx < numSavedSequences; idx+=1)
		names+=";"+GetIndexedObjName("", 1, idx)
	endfor

	return names

End

//_____________________________________________________________________________
//
// makepopnames() scans the stored sequences folder to populate the drop-down menu
//_____________________________________________________________________________
//
//Function/S makepopnamesOLD()
//	SetDatafolder Root:ExpParams
//	WAVE/T LoadWaveFiles
//	
//	Make/O/N=0/T LoadWaveFiles
//	Variable fileIndex = 0
//	
//	do
//		String fileName
//		fileName = IndexedFile(SequencesPath, fileIndex, "????")
//		if (strlen(fileName) == 0)
//			break
//		endif
//		InsertPoints 0,1,LoadWaveFiles
//		LoadWaveFiles[0] = fileName
//		fileIndex += 1
//	while(1)
//	
//	String names=" "
//	Variable i=0
//
//	For(i=0;i<Dimsize(LoadWavefiles,0);i+=1)
//		names+=";"+LoadWaveFiles[i]
//	EndFor
//	Return names
//
//End

//_____________________________________________________________________________
//
// Create panel for defining new experimental sequence types
//_____________________________________________________________________________
//
Window PulseCreator() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(1189,1412,1522,1751) as "Pulse Creator"
	ModifyPanel cbRGB=(65280,65280,48896)
	Button NewItem,pos={15,16},size={80,20},proc=NewItemPressed,title="New Item"
	Button NewItem,userdata=  "9"
	Button DeleteItem,pos={117,16},size={80,20},proc=DeleteItemPressed,title="Delete Item"
	Button SetLoops,pos={219,16},size={80,20},proc=SetLoopsPressed,title="Set Loops"
	PopupMenu StepType1,pos={15,46},size={94,21},proc=StepTypeChanged,title="Step 1"
	PopupMenu StepType1,mode=1,popvalue="Delay",value= #"MakeNames()"
	ValDisplay GroupVal1,pos={285,50},size={20,16},frame=2
	ValDisplay GroupVal1,limits={0,0,0},barmisc={0,1000}
	ValDisplay GroupVal1,value= #"root:ExpParams:GroupVals[0]"
	PopupMenu StepType2,pos={15,76},size={94,21},proc=StepTypeChanged,title="Step 2"
	PopupMenu StepType2,mode=1,popvalue="Delay",value= #"MakeNames()"
	CheckBox NewGroup2,pos={200,80},size={80,15},proc=NewGroupChecked,title="New Group"
	CheckBox NewGroup2,value= 0
	ValDisplay GroupVal2,pos={285,80},size={20,16},frame=2
	ValDisplay GroupVal2,limits={0,0,0},barmisc={0,1000}
	ValDisplay GroupVal2,value= #"root:ExpParams:GroupVals[1]"
	PopupMenu StepType3,pos={15,106},size={94,21},proc=StepTypeChanged,title="Step 3"
	PopupMenu StepType3,mode=1,popvalue="Delay",value= #"MakeNames()"
	CheckBox NewGroup3,pos={200,110},size={80,15},proc=NewGroupChecked,title="New Group"
	CheckBox NewGroup3,value= 0
	ValDisplay GroupVal3,pos={285,110},size={20,16},frame=2
	ValDisplay GroupVal3,limits={0,0,0},barmisc={0,1000}
	ValDisplay GroupVal3,value= #"root:ExpParams:GroupVals[2]"
	PopupMenu StepType4,pos={15,136},size={94,21},proc=StepTypeChanged,title="Step 4"
	PopupMenu StepType4,mode=1,popvalue="Delay",value= #"MakeNames()"
	CheckBox NewGroup4,pos={200,140},size={80,15},proc=NewGroupChecked,title="New Group"
	CheckBox NewGroup4,value= 0
	ValDisplay GroupVal4,pos={285,140},size={20,16},frame=2
	ValDisplay GroupVal4,limits={0,0,0},barmisc={0,1000}
	ValDisplay GroupVal4,value= #"root:ExpParams:GroupVals[3]"
	PopupMenu StepType5,pos={15,166},size={94,21},proc=StepTypeChanged,title="Step 5"
	PopupMenu StepType5,mode=1,popvalue="Delay",value= #"MakeNames()"
	CheckBox NewGroup5,pos={200,170},size={80,15},proc=NewGroupChecked,title="New Group"
	CheckBox NewGroup5,value= 0
	ValDisplay GroupVal5,pos={285,170},size={20,16},frame=2
	ValDisplay GroupVal5,limits={0,0,0},barmisc={0,1000}
	ValDisplay GroupVal5,value= #"root:ExpParams:GroupVals[4]"
	PopupMenu StepType6,pos={15,196},size={94,21},proc=StepTypeChanged,title="Step 6"
	PopupMenu StepType6,mode=1,popvalue="Delay",value= #"MakeNames()"
	CheckBox NewGroup6,pos={200,200},size={80,15},proc=NewGroupChecked,title="New Group"
	CheckBox NewGroup6,value= 0
	ValDisplay GroupVal6,pos={285,200},size={20,16},frame=2
	ValDisplay GroupVal6,limits={0,0,0},barmisc={0,1000}
	ValDisplay GroupVal6,value= #"root:ExpParams:GroupVals[5]"
	PopupMenu StepType7,pos={15,226},size={94,21},proc=StepTypeChanged,title="Step 7"
	PopupMenu StepType7,mode=1,popvalue="Delay",value= #"MakeNames()"
	CheckBox NewGroup7,pos={200,230},size={80,15},proc=NewGroupChecked,title="New Group"
	CheckBox NewGroup7,value= 0
	ValDisplay GroupVal7,pos={285,230},size={20,16},frame=2
	ValDisplay GroupVal7,limits={0,0,0},barmisc={0,1000}
	ValDisplay GroupVal7,value= #"root:ExpParams:GroupVals[6]"
	PopupMenu StepType8,pos={15,256},size={94,21},proc=StepTypeChanged,title="Step 8"
	PopupMenu StepType8,mode=1,popvalue="Delay",value= #"MakeNames()"
	CheckBox NewGroup8,pos={200,260},size={80,15},proc=NewGroupChecked,title="New Group"
	CheckBox NewGroup8,value= 0
	ValDisplay GroupVal8,pos={285,260},size={20,16},frame=2
	ValDisplay GroupVal8,limits={0,0,0},barmisc={0,1000}
	ValDisplay GroupVal8,value= #"root:ExpParams:GroupVals[7]"
	PopupMenu StepType9,pos={15,286},size={94,21},proc=StepTypeChanged,title="Step 9"
	PopupMenu StepType9,mode=1,popvalue="Delay",value= #"MakeNames()"
	CheckBox NewGroup9,pos={200,290},size={80,15},proc=NewGroupChecked,title="New Group"
	CheckBox NewGroup9,value= 0
	ValDisplay GroupVal9,pos={285,290},size={20,16},frame=2
	ValDisplay GroupVal9,limits={0,0,0},barmisc={0,1000}
	ValDisplay GroupVal9,value= #"root:ExpParams:GroupVals[8]"
EndMacro


//_____________________________________________________________________________
//
// DataLoader()
//_____________________________________________________________________________
//
Window Dataloader() : Panel
	PauseUpdate; Silent 1		// building window...
	DoWindow /K Dataloader
	NewPanel /N=Dataloader /K=1 /W=(75,110,408,210) as "Data Loader"
	ModifyPanel cbRGB=(65534,65534,65534)
	Checkbox SingleVariable, pos={35,15},size={80,20},proc=SingleVariable_proc,title="Single Variable", mode=1
	Checkbox VariableCorrelation, pos={165,15},size={80,20},proc=VariableCorrelation_proc,title="Variable Correlation",mode=1,disable=1
EndMacro


//_____________________________________________________________________________
//
// Create control panel for manual control of DDS output and sequencer outputs
//_____________________________________________________________________________
//
Window OverrideVariables() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(780,1284,1053,2285) as "Override Variables"
	ModifyPanel cbRGB=(65280,48896,48896)
	TitleBox DDS1Namebox,pos={50,15},size={150,20},title="DDS #1: State Detection"
	TitleBox DDS1Namebox,labelBack=(0,0,0),font="Arial",frame=4
	TitleBox DDS1Namebox,fColor=(65535,65535,65535),anchor= MC,fixedSize=1
	SetVariable DDS1_FREQ_BOX,pos={18,40},size={227,18},bodyWidth=130,proc=DDS_wrapper,title="DDS1 Frequency"
	SetVariable DDS1_FREQ_BOX,font="Arial"
	SetVariable DDS1_FREQ_BOX,limits={0,400,1},value= root:ExpParams:DDS_INFO[0]
	SetVariable DDS1_PHASE_BOX,pos={39,60},size={206,18},bodyWidth=130,proc=DDS_wrapper,title="DDS1 Phase"
	SetVariable DDS1_PHASE_BOX,font="Arial"
	SetVariable DDS1_PHASE_BOX,limits={0,180,1},value= root:ExpParams:DDS_INFO[0][2]
	SetVariable DDS1_AMPL_BOX,pos={20,80},size={225,18},bodyWidth=130,proc=DDS_wrapper,title="DDS1 Amplitude"
	SetVariable DDS1_AMPL_BOX,font="Arial"
	SetVariable DDS1_AMPL_BOX,limits={0,1023,1},value= root:ExpParams:DDS_INFO[0][1]
	CheckBox DDS1_Override,pos={50,100},size={103,15},bodyWidth=130,proc=DDS_Overridewrapper,title="DDS 1 Override"
	CheckBox DDS1_Override,font="Arial",value= 0
	TitleBox DDS2Namebox,pos={50,140},size={150,20},title="DDS #2: Flourescence Detection"
	TitleBox DDS2Namebox,labelBack=(0,0,0),font="Arial",frame=4
	TitleBox DDS2Namebox,fColor=(65535,65535,65535),anchor= MC,fixedSize=1
	SetVariable DDS2_FREQ_BOX,pos={18,165},size={227,18},bodyWidth=130,proc=DDS_wrapper,title="DDS2 Frequency"
	SetVariable DDS2_FREQ_BOX,font="Arial"
	SetVariable DDS2_FREQ_BOX,limits={0,400,1},value= root:ExpParams:DDS_INFO[1]
	SetVariable DDS2_PHASE_BOX,pos={39,185},size={206,18},bodyWidth=130,proc=DDS_wrapper,title="DDS2 Phase"
	SetVariable DDS2_PHASE_BOX,font="Arial"
	SetVariable DDS2_PHASE_BOX,limits={0,180,1},value= root:ExpParams:DDS_INFO[1][2]
	SetVariable DDS2_AMPL_BOX,pos={20,205},size={225,18},bodyWidth=130,proc=DDS_wrapper,title="DDS2 Amplitude"
	SetVariable DDS2_AMPL_BOX,font="Arial"
	SetVariable DDS2_AMPL_BOX,limits={0,1023,1},value= root:ExpParams:DDS_INFO[1][1]
	CheckBox DDS2_Override,pos={50,225},size={103,15},bodyWidth=130,proc=DDS_Overridewrapper,title="DDS 2 Override"
	CheckBox DDS2_Override,font="Arial",value= 0
	TitleBox DDS3Namebox,pos={50,265},size={150,20},title="DDS #3: Doppler Cooling"
	TitleBox DDS3Namebox,labelBack=(0,0,0),font="Arial",frame=4
	TitleBox DDS3Namebox,fColor=(65535,65535,65535),anchor= MC,fixedSize=1
	SetVariable DDS3_FREQ_BOX,pos={18,290},size={227,18},bodyWidth=130,proc=DDS_wrapper,title="DDS3 Frequency"
	SetVariable DDS3_FREQ_BOX,font="Arial"
	SetVariable DDS3_FREQ_BOX,limits={0,400,1},value= root:ExpParams:DDS_INFO[2]
	SetVariable DDS3_PHASE_BOX,pos={39,310},size={206,18},bodyWidth=130,proc=DDS_wrapper,title="DDS3 Phase"
	SetVariable DDS3_PHASE_BOX,font="Arial"
	SetVariable DDS3_PHASE_BOX,limits={0,180,1},value= root:ExpParams:DDS_INFO[2][2]
	SetVariable DDS3_AMPL_BOX,pos={20,330},size={225,18},bodyWidth=130,proc=DDS_wrapper,title="DDS3 Amplitude"
	SetVariable DDS3_AMPL_BOX,font="Arial"
	SetVariable DDS3_AMPL_BOX,limits={0,1023,1},value= root:ExpParams:DDS_INFO[2][1]
	CheckBox DDS3_Override,pos={50,350},size={103,15},bodyWidth=130,proc=DDS_Overridewrapper,title="DDS 3 Override"
	CheckBox DDS3_Override,font="Arial",value= 1
	TitleBox EO1Namebox,pos={50,390},size={150,20},title="EO #1: Optical Pumping"
	TitleBox EO1Namebox,labelBack=(0,0,0),font="Arial",frame=4
	TitleBox EO1Namebox,fColor=(65535,65535,65535),anchor= MC,fixedSize=1
	SetVariable EO1_FREQ_BOX,pos={27,415},size={218,18},bodyWidth=130,proc=EO_wrapper,title="EO1 Frequency"
	SetVariable EO1_FREQ_BOX,font="Arial"
	SetVariable EO1_FREQ_BOX,limits={2000,7500,1},value= root:ExpParams:EO_INFO[0][1]
	SetVariable EO1_AMPL_BOX,pos={23,435},size={222,18},bodyWidth=130,proc=EO_wrapper,title="EO1 Attenuation"
	SetVariable EO1_AMPL_BOX,font="Arial"
	SetVariable EO1_AMPL_BOX,limits={0,1023,1},value= root:ExpParams:EO_INFO[0][2]
	CheckBox EO1_Override,pos={50,455},size={94,15},bodyWidth=130,proc=EO_Overridewrapper,title="EO 1 Override"
	CheckBox EO1_Override,font="Arial",value= 0
	TitleBox EO2Namebox,pos={50,495},size={150,20},title="EO #2: Cooling"
	TitleBox EO2Namebox,labelBack=(0,0,0),font="Arial",frame=4
	TitleBox EO2Namebox,fColor=(65535,65535,65535),anchor= MC,fixedSize=1
	SetVariable EO2_FREQ_BOX,pos={27,520},size={218,18},bodyWidth=130,proc=EO_wrapper,title="EO2 Frequency"
	SetVariable EO2_FREQ_BOX,font="Arial"
	SetVariable EO2_FREQ_BOX,limits={2000,7500,1},value= root:ExpParams:EO_INFO[1][1]
	SetVariable EO2_AMPL_BOX,pos={23,540},size={222,18},bodyWidth=130,proc=EO_wrapper,title="EO2 Attenuation"
	SetVariable EO2_AMPL_BOX,font="Arial"
	SetVariable EO2_AMPL_BOX,limits={0,1023,1},value= root:ExpParams:EO_INFO[1][2]
	CheckBox EO2_Override,pos={50,560},size={94,15},bodyWidth=130,proc=EO_Overridewrapper,title="EO 2 Override"
	CheckBox EO2_Override,font="Arial",value= 0
	TitleBox EO3Namebox,pos={50,600},size={150,20},title="EO #3: Repump"
	TitleBox EO3Namebox,labelBack=(0,0,0),font="Arial",frame=4
	TitleBox EO3Namebox,fColor=(65535,65535,65535),anchor= MC,fixedSize=1
	SetVariable EO3_FREQ_BOX,pos={27,625},size={218,18},bodyWidth=130,proc=EO_wrapper,title="EO3 Frequency"
	SetVariable EO3_FREQ_BOX,font="Arial"
	SetVariable EO3_FREQ_BOX,limits={2000,7500,1},value= root:ExpParams:EO_INFO[2][1]
	SetVariable EO3_AMPL_BOX,pos={23,645},size={222,18},bodyWidth=130,proc=EO_wrapper,title="EO3 Attenuation"
	SetVariable EO3_AMPL_BOX,font="Arial"
	SetVariable EO3_AMPL_BOX,limits={0,1023,1},value= root:ExpParams:EO_INFO[2][2]
	CheckBox EO3_Override,pos={50,665},size={94,15},bodyWidth=130,proc=EO_Overridewrapper,title="EO 3 Override"
	CheckBox EO3_Override,font="Arial",value= 0
	TitleBox TTLtitle,pos={50,705},size={150,20},title="TTL Controls"
	TitleBox TTLtitle,labelBack=(0,0,0),font="Arial",frame=4
	TitleBox TTLtitle,fColor=(65535,65535,65535),anchor= MC,fixedSize=1
	TitleBox TTLtitle1,pos={25,730},size={50,20},title="TTL1"
	TitleBox TTLtitle1,labelBack=(65535,65535,65535),font="Arial",frame=0
	TitleBox TTLtitle1,anchor= MC,fixedSize=1
	CheckBox TTL1_Switch,pos={75,734},size={52,15},bodyWidth=130,proc=TTL_wrapper,title="On/Off"
	CheckBox TTL1_Switch,font="Arial",value= 1
	CheckBox TTL1_Override,pos={135,734},size={64,15},bodyWidth=130,proc=TTL_wrapper,title="Override"
	CheckBox TTL1_Override,font="Arial",value= 0
	TitleBox TTLtitle2,pos={25,750},size={50,20},title="TTL2"
	TitleBox TTLtitle2,labelBack=(65535,65535,65535),font="Arial",frame=0
	TitleBox TTLtitle2,anchor= MC,fixedSize=1
	CheckBox TTL2_Switch,pos={75,754},size={52,15},bodyWidth=130,proc=TTL_wrapper,title="On/Off"
	CheckBox TTL2_Switch,font="Arial",value= 0
	CheckBox TTL2_Override,pos={135,754},size={64,15},bodyWidth=130,proc=TTL_wrapper,title="Override"
	CheckBox TTL2_Override,font="Arial",value= 0
	TitleBox TTLtitle3,pos={25,770},size={50,20},title="TTL3"
	TitleBox TTLtitle3,labelBack=(65535,65535,65535),font="Arial",frame=0
	TitleBox TTLtitle3,anchor= MC,fixedSize=1
	CheckBox TTL3_Switch,pos={75,774},size={52,15},bodyWidth=130,proc=TTL_wrapper,title="On/Off"
	CheckBox TTL3_Switch,font="Arial",value= 0
	CheckBox TTL3_Override,pos={135,774},size={64,15},bodyWidth=130,proc=TTL_wrapper,title="Override"
	CheckBox TTL3_Override,font="Arial",value= 0
	TitleBox TTLtitle4,pos={25,790},size={50,20},title="TTL4"
	TitleBox TTLtitle4,labelBack=(65535,65535,65535),font="Arial",frame=0
	TitleBox TTLtitle4,anchor= MC,fixedSize=1
	CheckBox TTL4_Switch,pos={75,794},size={52,15},bodyWidth=130,proc=TTL_wrapper,title="On/Off"
	CheckBox TTL4_Switch,font="Arial",value= 1
	CheckBox TTL4_Override,pos={135,794},size={64,15},bodyWidth=130,proc=TTL_wrapper,title="Override"
	CheckBox TTL4_Override,font="Arial",value= 0
	TitleBox TTLtitle5,pos={25,810},size={50,20},title="TTL5"
	TitleBox TTLtitle5,labelBack=(65535,65535,65535),font="Arial",frame=0
	TitleBox TTLtitle5,anchor= MC,fixedSize=1
	CheckBox TTL5_Switch,pos={75,814},size={52,15},bodyWidth=130,proc=TTL_wrapper,title="On/Off"
	CheckBox TTL5_Switch,font="Arial",value= 0
	CheckBox TTL5_Override,pos={135,814},size={64,15},bodyWidth=130,proc=TTL_wrapper,title="Override"
	CheckBox TTL5_Override,font="Arial",value= 0
	TitleBox TTLtitle6,pos={25,830},size={50,20},title="TTL6"
	TitleBox TTLtitle6,labelBack=(65535,65535,65535),font="Arial",frame=0
	TitleBox TTLtitle6,anchor= MC,fixedSize=1
	CheckBox TTL6_Switch,pos={75,834},size={52,15},bodyWidth=130,proc=TTL_wrapper,title="On/Off"
	CheckBox TTL6_Switch,font="Arial",value= 0
	CheckBox TTL6_Override,pos={135,834},size={64,15},bodyWidth=130,proc=TTL_wrapper,title="Override"
	CheckBox TTL6_Override,font="Arial",value= 0
	TitleBox TTLtitle7,pos={25,850},size={50,20},title="TTL7"
	TitleBox TTLtitle7,labelBack=(65535,65535,65535),font="Arial",frame=0
	TitleBox TTLtitle7,anchor= MC,fixedSize=1
	CheckBox TTL7_Switch,pos={75,854},size={52,15},bodyWidth=130,proc=TTL_wrapper,title="On/Off"
	CheckBox TTL7_Switch,font="Arial",value= 0
	CheckBox TTL7_Override,pos={135,854},size={64,15},bodyWidth=130,proc=TTL_wrapper,title="Override"
	CheckBox TTL7_Override,font="Arial",value= 0
	TitleBox TTLtitle8,pos={25,870},size={50,20},title="399 "
	TitleBox TTLtitle8,labelBack=(65535,65535,65535),font="Arial",frame=0
	TitleBox TTLtitle8,anchor= MC,fixedSize=1
	CheckBox TTL8_Switch,pos={75,874},size={52,15},bodyWidth=130,proc=TTL_wrapper,title="On/Off"
	CheckBox TTL8_Switch,font="Arial",value= 1
	CheckBox TTL8_Override,pos={135,874},size={64,15},bodyWidth=130,proc=TTL_wrapper,title="Override"
	CheckBox TTL8_Override,font="Arial",value= 1
	Button SeqInit,pos={21,904},size={70,20},proc=Seqinit,title="Seq Init"
	Button DC_ConInit,pos={95,904},size={70,20},proc=DC_ctrl_Init,title="DC Init"
	Button PulserInit,pos={169,904},size={70,20},proc=Pulse_Init,title="Pulser Init"
	Button PulseCreator_init,pos={21,926},size={70,20},proc=PulseCreator_Init,title="Creat Init"
EndMacro

//_____________________________________________________________________________
//
//	ScrollHook(info) allows the user to scroll the controls in a panel by scrolling the mouse
//	wheel. It is actually repositioning all the controls when the mouse wheel rotates.
//_____________________________________________________________________________
//
Function ScrollHook(info)
	Struct WMWinHookStruct &info
 
	if(info.eventCode == 22)
		string controls = ControlNameList(info.winName)
		variable i
		for(i=0;i<itemsinlist(controls);i+=1)
			string control = stringfromlist(i,controls)
			if ( cmpstr(control, "Sequence") != 0)
				ModifyControl $control pos+={0,20*info.wheelDy}
			endif
		endfor
	endif
End