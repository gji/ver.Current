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
	// DC_Init()
	
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
	doWindow/HIDE=? DCCtrl
	If(V_FLag)
		KillWindow DCCtrl
	Endif
		doWindow/HIDE=? DataLoader
	If(V_FLag)
		KillWindow DataLoader
	Endif
	// Creates Windows	
	//	DataLoader()
	PulseCreator()	// For Creating Pulse Sequences
	Pulse()			// For Running Pulse Sequence
	// DCCtrl() 			// For Setting DC Bias on Trap
	// DDS_Control()	// For Setting DDS Values
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
	
	String/G SEQ_NAME 					= "SEQ_FPGA"
	String/G DDS_NAME 					= "DDS_FPGA"
	String/G PMT_NAME 					= "PMT_FPGA"
	String/G TDC_NAME 					= "TDC_FPGA"
	String/G SEQ_PORT 					= "COM18"
	String/G DDS_PORT 					= "COM17"
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
		
	Variable/G DELAY					=	TTL_00	
	Variable/G COOL						=	TTL_01
	Variable/G PUMP						=	TTL_02
	Variable/G STATE_DET				=	TTL_02
	Variable/G AWG_TRIG				=	TTL_03
	Variable/G DAC_TRIG					=	TTL_04	
	Variable/G FLR_DET					=	TTL_04|TTL_01
	Variable/G PUMP						=	TTL_02|TTL_03
	Variable/G COOL_SHTR				=	TTL_05
	Variable/G LOAD_SHTR				=	TTL_06
	Variable/G RAMAN1					=	TTL_07
	Variable/G RAMAN2					=	TTL_08
	Variable/G PMT						=	DI_01	// PMT might be gated, might need to add a TTL pulse here

	Variable/G TRAP_RF_FREQ			= 	30 // MHz
	Variable/G TRAP_RF_AMP			=	100 // Max Amp
	Variable/G TRAP_RF_PHASE			=	0 	
	
	Variable/G COOL_FREQ				= 	290 // MHz
	Variable/G COOL_AMP				=	100 // Max Amp
	Variable/G COOL_PHASE				=	0 	
	
	Variable/G PUMP_FREQ				= 	300 // MHz
	Variable/G PUMP_AMP				=	100 // Max Amp
	Variable/G PUMP_PHASE				=	0 	
	
	Variable/G STATE_DET_FREQ			=	220 // MHz
	Variable/G STATE_DET_AMP			=	100 // Max Amp
	Variable/G STATE_DET_PHASE		=	0	
	
	Variable/G FLR_DET_FREQ			=	220 // MHz
	Variable/G FLR_DET_AMP			=	100 // Max Amp
	Variable/G FLR_DET_PHASE			=	0

	Variable/G MIN_POSITION = 0			// Lowest ion position index (voltage set specification)
	Variable/G MAX_POSITION = 10		// Highest ion position index (voltage set specification)
	Variable/G DEFAULT_POSITION = 0	// Default ion position index (voltage set specification)
	String/G	WAVE_Ez					=	":waveforms:Blade_Ez.csv"
	String/G	WAVE_Ex					=	":waveforms:Blade_Ex.csv"
	String/G	WAVE_Ey					=	":waveforms:Blade_Ey.csv"
	String/G	WAVE_Harm				=	":waveforms:Blade_Harmonic.csv"		
	String/G	WAVE_Hardware				=	":waveforms:Blade_Hardware.csv"

	//Variables for Pulse Program
	NewDataFolder/O root:DataAnalysis
	
	Make/O/N=0 GroupVals
	Make/O/N=0 PopupVals
	
	Variable/G SequenceCurrent							=	0
	Variable/G VerticalButtonPosition					=	16
	Variable/G VerticalLoopPosition						=	16
	Variable/G GroupNumber									=	0
	Variable/G GroupError									= 	0
	Make/O/N=10 NameWave									=	{DELAY,COOL,STATE_DET,FLR_DET,PUMP,COOL_SHTR,LOAD_SHTR,RAMAN1,RAMAN2,PMT}
	Make/O/T/N=10 TTLNames									=	{"Delay","Cool","State Detection","Flourescence Detection","Pump","Cool Shutter","LoadShutter","Raman 1", "Raman 2","PMT","935 EO", "Rotation", "MSGate", "SBCooling"}			
	// The following should be matched up, in order, with TTLNames. The indexes denote the scan types labeled in SCAN_TITLES.
	// For example, 0 is for Delay, 0123 is for Cooling. 
	String/G 	 TTL_PARAMS				=	"0;0123;012345;012345;0;0;0;0123;0123;0;045;0678;0;"
	String/G		 SCAN_TITLES 				= "Duration;AO Frequency;AO Amplitude;AO Phase;EO Frequency;EO Power;Rotation Amplitude;Rotation Frequency;Rotation Phase"
	Make/O/T/N=4 DDSNames								=	{"Trap RF", "Cool","Pump", "Detect"}
	Make/O/T/N=4 DDSScans									=	{"Duration","Frequency","Amplitude","Phase"}
	Make/O/T/N=3 EONames									=	{"State Detection", "Flourescence Detection"}
	Make/O/T/N=1 EONotDDSNames							=	{"935 EO"}
	Make/O/T/N=3 EONOTDDSSCans							=	{"Duration","EO Frequency","EOAmplitude"}
	Make/O/T/N=6 EOScans									=	{"Duration","AO Frequency","AO Amplitude","AO Phase","EO Frequency","EO Amplitude"}
	Make/O/N=(1024,3)	PulseCreatorWave					=	0
	Make/O/N=(1024,3) dataloaderwave						=	0
	Variable/G TooLong										=	0

	PathInfo home				// Save home folder of unpacked experiment folder to S_path
	String homeFolder = S_path	// Save path to persistent local variable
	// Make save paths two levels up. Assumes folder structure like IgorCode -> Experiment64 -> Experiment64Folder ("home")
	NewPath/O/C/Q/Z SequencesPath, homeFolder+"..:..:Sequences:"
	NewPath/O/C/Q/Z SettingsPath, homeFolder+"..:..:Settings:"
	NewPath/O/C/Q/Z DataPath, homeFolder+"..:..:Data:"

	Variable/G made1											=	0
	Variable/G made2											=	0
	Variable/G made											=	0

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

	// Create 2D wave for DDS parameters according to the number of channels and the 
	// channel mapping defined in Config.ipf
	Make/O/N=(DDS_Channels,DDS_Params+1) 	DDS_INFO
	Make/O/N=5 							COMP_INFO		 = {0,0,0,1,1}
	Make/O/T/N=5 						WAVE_INFO		 = {WAVE_Ez, WAVE_Ex, WAVE_Ey, WAVE_Harm, WAVE_Hardware}

	Variable j,i
	for(i=0;i!=(DDS_Channels); i+=1)
		switch(i)
			case TRAP_RF_CNL:
				For(j=0; j!=(DDS_Params+1); j+=1)	
					switch(j)
						case 0:		
							DDS_INFO[i][j]	=	TRAP_RF_FREQ
							break
						case 1:
							DDS_INFO[i][j]	=	TRAP_RF_AMP
							break
						case 2:
							DDS_INFO[i][j]	=	TRAP_RF_PHASE
							break
						default:
							DDS_INFO[i][j]	=	0
					EndSwitch
				EndFor
				break
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
			case PUMP_CNL:
				For(j=0; j!=(DDS_Params+1); j+=1)	
					switch(j)
						case 0:		
							DDS_INFO[i][j]	=	PUMP_FREQ
							break
						case 1:
							DDS_INFO[i][j]	=	PUMP_AMP
							break
						case 2:
							DDS_INFO[i][j]	=	PUMP_PHASE
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
	// updateVoltages()
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
	LoadWave/M/K=2/U={0,0,1,0}/O/B="N=HARDWARE_MAP;" /J/P=home WAVE_INFO[4]
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
	
	Make/O/N=(NUM_ELECT,4)	FIELDS
	Make/O/N=(NUM_ELECT) RAW_VOLTAGES
	Make/O/N=(NUM_DC_OUTS)  OUT_VOLTAGES
	Make/T/O/N=(NUM_DACS) CMDS	
	
	for(i=0; i<4; i+=1) // There are 4 different waveforms (x,y,z,harmonic). Also see updateVoltages.
		SetDataFolder root:DCVolt:temp
		WAVE t = LoadDCWaveMatrixHelper(WAVE_INFO[i], num2str(i)) // Grab each waveform
		Make/O/N=(DimSize(t,0),NUM_ELECT+1) ::$("mat"+num2str(i)) // Extra row for indicies
		WAVE out = ::$("mat"+num2str(i))
		for(k=0; k<DimSize(t,0);k+=1)
			out[k][0] = t[k][0]
			for(j=1;j<NUM_ELECT+1;j+=1)
				out[k][j]=0	
			endfor
		endfor
		for(j=1; j<DimSize(t,1);j+=1)
			FindValue/TEXT=GetDimLabel(t,1,j) HARDWARE_MAP // Look for electrode, stores into V_Value
			Variable col, row
			col=floor(V_value/DimSize(HARDWARE_MAP, 0))
			row=V_value-col*DimSize(HARDWARE_MAP, 0)
			for(k=0; k<DimSize(t,0);k+=1)
				out[k][row+1] = t[k][j]
			endfor
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
Function Seq_init()
	NewDataFolder/O/S root:DDS	
	NewDataFolder/O/S root:Sequencer
	SetDataFolder root:Sequencer	
	NewDataFolder/O/S :Data
	
	Make/O PulseProgram
	Make/B/U/O/n=0 WriteWave
	
	SetDataFolder root:Sequencer:Data	
	Make/B/U/O data_01
	Make/B/U/O data_02
	Make/B/U/O data_03
	Make/B/U/O data_04
	Make/B/U/O data_05
	Make/B/U/O data_06
	Make/B/U/O data_07	
	Make/B/U/O data_08		
	
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
	NewPanel /N=DCCtrl/K=1 /W=(30+0,75+0,30+260,75+260) as "Trap DC Voltage Control"
	ModifyPanel cbRGB=(65534,65534,65534)
	Button zvalp,pos={135,15},size={50,20},proc=ButtonProc,title="Z+"
	Button zvalm,pos={195,15},size={50,20},proc=ButtonProc,title="Z-"
	Button xvalp,pos={135,45},size={50,20},proc=ButtonProc,title="X+"
	Button xvalm,pos={195,45},size={50,20},proc=ButtonProc,title="X-"
	Button yvalp,pos={135,75},size={50,20},proc=ButtonProc,title="Y+"
	Button yvalm,pos={195,75},size={50,20},proc=ButtonProc,title="Y-"
	Button hvalp,pos={135,105},size={50,20},proc=ButtonProc,title="H+"
	Button hvalm,pos={195,105},size={50,20},proc=ButtonProc,title="H-"
	Button gvalp,pos={135,135},size={50,20},proc=ButtonProc,title="G+"
	Button gvalm,pos={195,135},size={50,20},proc=ButtonProc,title="G-"
	SetVariable zpos,pos={20,17.5},size={100,20},bodyWidth=60,proc=fieldUpdate,title="Z Field"
	SetVariable zpos,limits={-inf,inf,0},value= root:ExpParams:COMP_INFO[0]
	SetVariable xpos,pos={20,47.5},size={100,20},bodyWidth=60,proc=fieldUpdate,title="X Field"
	SetVariable xpos,limits={-inf,inf,0},value= root:ExpParams:COMP_INFO[1]
	SetVariable ypos,pos={20,77.5},size={100,20},bodyWidth=60,proc=fieldUpdate,title="Y Field"
	SetVariable ypos,limits={-inf,inf,0},value= root:ExpParams:COMP_INFO[2]
	SetVariable harmScale,pos={20,107.5},size={100,20},bodyWidth=60,proc=fieldUpdate,title="Harm. SF"
	SetVariable harmScale,limits={-inf,inf,0},value= root:ExpParams:COMP_INFO[3]
	SetVariable globScale,pos={20,137.5},size={100,20},bodyWidth=60,proc=fieldUpdate,title="Glob. SF"
	SetVariable globScale,limits={-inf,inf,0},value= root:ExpParams:COMP_INFO[4]
	SetVariable posIon,pos={20,167.5},size={100,20},bodyWidth=60,proc=fieldUpdate,title="Ion Pos."
	SetVariable posIon,limits={-inf,inf,0},value= root:ExpParams:CUR_POS
	Button update,pos={135,195},size={110,20},proc=Update,title="Update"
	Button settings,pos={135,225},size={110,20},proc=openSettings,title="Settings"
	CheckBox liveupdate,pos={46,198},size={76,14},proc=LiveUpCheck,title="Live Update"
	CheckBox liveupdate,value= 0,side= 1
EndMacro

//_____________________________________________________________________________
//
// Create DC control settings panel
//_____________________________________________________________________________
//
Window DCSettings(l,r,t,b) : Panel
	Variable l,r,t,b
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(r+8,t+30,r+8+400,t+30+165+30) as "DC Voltage Settings"
	ModifyPanel cbRGB=(65534,65534,65534)
	SetVariable zfile,pos={100,17.5},size={195,20},bodyWidth=185,title="Z Voltage File"
	SetVariable zfile,value= root:ExpParams:WAVE_INFO[0]
	SetVariable xfile,pos={100,47.5},size={195,20},bodyWidth=185,title="X Voltage File"
	SetVariable xfile,value= root:ExpParams:WAVE_INFO[1]
	SetVariable yfile,pos={100,77.5},size={195,20},bodyWidth=185,title="Y Voltage File"
	SetVariable yfile,value= root:ExpParams:WAVE_INFO[2]
	SetVariable hfile,pos={100,107.5},size={195,20},bodyWidth=185,title="Harm. Voltage File"
	SetVariable hfile,value= root:ExpParams:WAVE_INFO[3]
	SetVariable dfile,pos={100,137.5},size={195,20},bodyWidth=185,title="Hardware Map File"
	SetVariable dfile,value= root:ExpParams:WAVE_Hardware
	Button zopen,pos={300,15},size={50,20},proc=OpenWaveFile,title="Open"
	Button xopen,pos={300,45},size={50,20},proc=OpenWaveFile,title="Open"
	Button yopen,pos={300,75},size={50,20},proc=OpenWaveFile,title="Open"
	Button hdopen,pos={300,105},size={50,20},proc=OpenWaveFile,title="Open"
	Button dopen,pos={300,135},size={50,20},proc=OpenWaveFile,title="Open"
	Button updateFields,pos={137.5,165},size={135,20},proc=OpenWaveFile,title="Update Field Waves"
EndMacro

//_____________________________________________________________________________
//
// Create DDS control panel
//_____________________________________________________________________________
//
Window DDS_Control() : Panel
	SetDataFolder root:DDS
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(30+0,75+298,30+260,75+298+170) as "DDS_Control"
	ModifyPanel cbRGB=(65534,65534,65534)
	SetVariable DDS1_FREQ_BOX,pos={50,15},size={195,20},bodyWidth=130,proc=DDS_wrapper,title="DDS1 Frequency"
	SetVariable DDS1_FREQ_BOX,font="Arial"
	SetVariable DDS1_FREQ_BOX,limits={0,400,0.01},value= root:ExpParams:DDS_INFO[0][0]
	SetVariable DDS2_FREQ_BOX,pos={50,35},size={195,20},bodyWidth=130,proc=DDS_wrapper,title="DDS2 Frequency"
	SetVariable DDS2_FREQ_BOX,font="Arial"
	SetVariable DDS2_FREQ_BOX,limits={0,400,0.01},value= root:ExpParams:DDS_INFO[1][0]
	SetVariable DDS1_PHASE_BOX,pos={50,65},size={195,20},bodyWidth=130,proc=DDS_wrapper,title="DDS1 Amplitude"
	SetVariable DDS1_PHASE_BOX,font="Arial"
	SetVariable DDS1_PHASE_BOX,limits={0,180,1},value= root:ExpParams:DDS_INFO[0][1]
	SetVariable DDS2_PHASE_BOX,pos={50,85},size={195,20},bodyWidth=130,proc=DDS_wrapper,title="DDS2 Amplitude"
	SetVariable DDS2_PHASE_BOX,font="Arial"
	SetVariable DDS2_PHASE_BOX,limits={0,180,1},value= root:ExpParams:DDS_INFO[1][1]
	SetVariable DDS1_AMPL_BOX,pos={50,115},size={195,20},bodyWidth=130,proc=DDS_wrapper,title="DDS1 Phase"
	SetVariable DDS1_AMPL_BOX,font="Arial"
	SetVariable DDS1_AMPL_BOX,limits={0,1023,1},value= root:ExpParams:DDS_INFO[0][2]
	SetVariable DDS2_AMPL_BOX,pos={50,135},size={195,20},bodyWidth=130,proc=DDS_wrapper,title="DDS2 Phase"
	SetVariable DDS2_AMPL_BOX,font="Arial"
	SetVariable DDS2_AMPL_BOX,limits={0,1023,1},value= root:ExpParams:DDS_INFO[1][2]
EndMacro

//_____________________________________________________________________________
//
// Create experimental sequence control panel
//_____________________________________________________________________________
//
Window Pulse() : Panel
	PauseUpdate; Silent 1		// building window...
	DoWindow /K Pulse
	NewPanel /N=Pulse /K=1 /W=(75,247,409,302) as "Pulse Program"
	ModifyPanel cbRGB=(65534,65534,65534)
	SetWindow Pulse hook(scroll)=ScrollHook
	PopupMenu Sequence,pos={68,18},size={202,21},bodyWidth=150,proc=PopMenuProc,title="Sequence",mode=1,value=makepopnames()
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
	NewPanel /K=1 /W=(996,136,1329,186) as "Pulse Creator"
	ModifyPanel cbRGB=(65534,65534,65534)
	Button NewItem,pos={15,16},size={80,20},proc=NewItemPressed,title="New Item",userdata="0" // store num of items in NewItem
	Button DeleteItem,pos={117,16},size={80,20},proc=DeleteItemPressed,title="Delete Item"
	Button SetLoops,pos={219,16},size={80,20},proc=SetLoopsPressed,title="Set Loops"
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
	SetDataFolder root:ExpParams
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(30+0,75+298,30+260,75+298+170) as "Override Variables"
	ModifyPanel cbRGB=(65534,65534,65534)
	Variable i=1
	Variable position=15
	String ddsTitle,eoTitle
	String ddsFreqBox,eoFreqBox
	String ddsPhaseBox
	String ddsAmpBox	,eoAmpBox
	String ddsOverride,eoOverride
	String TTLLabel
	String TTLSwitch
	String TTLOverride
	
	Do 
		
		ddstitle= "TitleBox DDS"+num2str(i)+"Namebox frame=4,fixedSize=1,font=\"Arial\",labelBack=(0,0,0),fColor=(65535,65535,65535),anchor=MC,pos={50,"+num2str(position)+"},size={150,20}, title=\"DDS #"+num2str(i)+": "+DDSNames[i-1]+"\""
		position+=25
		
		ddsFreqBox="SetVariable DDS"+num2str(i)+"_FREQ_BOX,pos={50,"+num2str(position)+"},size={195,20},bodyWidth=130,proc=DDS_wrapper,title=\"DDS"+num2str(i)+" Frequency\",font=\"Arial\",limits={0,400,0.01},value= root:ExpParams:DDS_INFO["+num2str(i-1)+"][0]"
		position+=20
		
		ddsPhaseBox="SetVariable DDS"+num2str(i)+"_PHASE_BOX,pos={50,"+num2str(position)+"},size={195,20},bodyWidth=130,proc=DDS_wrapper,title=\"DDS"+num2str(i)+" Phase\",font=\"Arial\",limits={0,180,1},value= root:ExpParams:DDS_INFO["+num2str(i-1)+"][2]"
		position+=20
		
		ddsAmpBox="SetVariable DDS"+num2str(i)+"_AMPL_BOX,pos={50,"+num2str(position)+"},size={195,20},bodyWidth=130,proc=DDS_wrapper,title=\"DDS"+num2str(i)+" Amplitude\",font=\"Arial\",limits={0,1023,1},value= root:ExpParams:DDS_INFO["+num2str(i-1)+"][1]"
		position+=20
		
		ddsOverride="Checkbox DDS"+num2str(i)+"_Override,pos={50,"+num2str(position)+"},size={195,20},bodyWidth=130,proc=DDS_Overridewrapper,title=\"DDS "+num2str(i)+" Override\",font=\"Arial\",value=0"

		position+=40
		Execute ddstitle
		Execute ddsFreqBox
		Execute ddsPhaseBox
		Execute ddsAmpBox
		Execute ddsOverride
		i+=1
	While (i<=4)
//	i=1
//		Do 
//		
//		eotitle= "TitleBox EO"+num2str(i)+"Namebox frame=4,fixedSize=1,font=\"Arial\",labelBack=(0,0,0),fColor=(65535,65535,65535),anchor=MC,pos={50,"+num2str(position)+"},size={150,20}, title=\"EO #"+num2str(i)+"\""
//		position+=25
//		
//		eoFreqBox="SetVariable EO"+num2str(i)+"_FREQ_BOX,pos={50,"+num2str(position)+"},size={195,20},bodyWidth=130,proc=EO_wrapper,title=\"EO"+num2str(i)+" Frequency\",font=\"Arial\",limits={2000,7500,1},value= root:ExpParams:DDS_INFO["+num2str(i-1)+"][0]"
//		position+=20
//		
//		eoAmpBox="SetVariable EO"+num2str(i)+"_AMPL_BOX,pos={50,"+num2str(position)+"},size={195,20},bodyWidth=130,proc=EO_wrapper,title=\"EO"+num2str(i)+" Amplitude\",font=\"Arial\",limits={0,1023,1},value= root:ExpParams:DDS_INFO["+num2str(i-1)+"][2]"
//		position+=20
//		
//		eoOverride="Checkbox EO"+num2str(i)+"_Override,pos={50,"+num2str(position)+"},size={195,20},bodyWidth=130,proc=EO_Overridewrapper,title=\"EO "+num2str(i)+" Override\",font=\"Arial\",value=0"
//
//		position+=40
//		Execute eotitle
//		Execute eoFreqBox
//		Execute eoAmpBox
//		Execute eoOverride
//		i+=1
//	While (i<=3)
	

	i=1
	TitleBox TTLtitle frame=4,fixedSize=1,labelBack=(0,0,0),fColor=(65535,65535,65535),font="Arial",anchor=MC,pos={50,position},size={150,20}, title="TTL Controls"
	position+=25
	Do
		TTLLabel="TitleBox TTLtitle"+num2str(i)+", frame=0,fixedSize=1,labelBack=(65535,65535,65535),fColor=(0,0,0),font=\"Arial\",anchor=MC,pos={25,"+num2str(position)+"},size={50,20}, title=\"TTL"+num2str(i)+"\""
		TTLSwitch="CheckBox TTL"+num2str(i)+"_Switch pos={75,"+num2str(position+4)+"},size={100,20},bodyWidth=130,proc=TTL_wrapper,title=\"On/Off\",font=\"Arial\",value=root:ExpParams:OverrideWave["+num2str(i-1)+"][0]"
		TTLOverride="Checkbox TTL"+num2str(i)+"_Override pos={135,"+num2str(position+4)+"},size={100,20},bodyWidth=130,proc=TTL_wrapper,title=\"Override\",font=\"Arial\",value=root:ExpParams:OverrideWave["+num2str(i-1)+"][1]"
		position+=20
		Execute TTLLabel
		Execute TTLSwitch
		Execute TTLOverride
		i+=1
	While (i<=8)

	MoveWindow/W=OverrideVariables 30,75,235,(position+130)*72/ScreenResolution
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