#pragma rtGlobals=1		// Use modern global access method.

Macro Exp_Init()

	DefaultGUIFont all={"Segoe UI", 12, 0}, panel={"Segoe UI",12,3}

// Fills appropriate waves and variables	
	
	Param_Init()
	DC_Init()
//	Seq_init()
//	MMCINIT
	
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
	doWindow/HIDE=? DCSettings
	If(V_FLag)
		KillWindow DCSettings
	Endif
// Creates Windows	
//	DataLoader()
//	PulseCreator()	//For Creating Pulse Sequences
//	Pulse()			//For Running Pulse Sequence
	DCCtrl() 			//For Setting DC Bias on Trap
//	DDS_Control()	//For Setting DDS Values
	OverrideVariables()
EndMacro

Function Param_Init()
	NewDataFolder/O/S root:ExpParams
	
	String/G SEQ_NAME 					= "Sequencer"
	String/G DDS_NAME 					= "DDS"
	
	String/G SEQ_PORT 					= ""
	String/G DDS_PORT 					= ""
	
	VDTGetPortListDescription2
	SVAR S_VDT
	String ports = S_VDT
	
	Variable n= ItemsInList(ports)
	Make/O/T/N=(n) devices = StringFromList(p,ports)
	Variable t;
	for(t=0; t<n; t+=1)
		String device = devices[t]
		if(strsearch(device, SEQ_NAME,0) != -1)
			SEQ_PORT = device[(strsearch(device,",",0)+1),strlen(device)]
		endif
		if(strsearch(device, DDS_NAME,0) != -1)
			DDS_PORT = device[(strsearch(device,",",0)+1),strlen(device)]
		endif
	endfor

	Variable/G LIVE_UP					= 	0
	Variable/G CUR_POS					= 	LOAD_POS		
	
	Variable/G VAR_TTL_01					= TTL_01
	Variable/G VAR_TTL_02					= TTL_02
	Variable/G VAR_TTL_03					= TTL_03
	Variable/G VAR_TTL_04					= TTL_04
	Variable/G VAR_TTL_05					= TTL_05
	Variable/G VAR_TTL_06					= TTL_06
	Variable/G VAR_TTL_07					= TTL_07
	Variable/G VAR_TTL_08					= TTL_08
	
	Variable/G DELAY						=	TTL_00	
	Variable/G COOL						=	TTL_01
	Variable/G STATE_DET				=	TTL_02
	Variable/G FLR_DET					=	TTL_04|TTL_01
	Variable/G PUMP						=	TTL_02|TTL_03
	Variable/G COOL_SHTR				=	TTL_05
	Variable/G LOAD_SHTR				=	TTL_06
	Variable/G RAMAN1					=	TTL_07
	Variable/G RAMAN2					=	TTL_08
	Variable/G PMT						=	DI_01	// PMT might be gated, might need to add a TTL pulse here

	// The following should be matched up, in order, with TTLNames
	// Eg. 0 is for Delay, 0123 is for Cooling
	// 0 is duration
	// 1 is for AO frequency
	// 2 is for AO amplitude
	// 3 is for AO phase
	// 4 is for EO frequency
	// 5 is for EO power
	String/G 	 TTL_PARAMS				=	"0;0123;012345;012345;0;0;0;0123;0123;0;045"
	
	Variable/G COOL_FREQ				= 	200 // MHz
	Variable/G COOL_AMP					=	100 // Max Amp
	Variable/G COOL_PHASE				=	0 	
	
	Variable/G STATE_DET_FREQ			=	220 // MHz
	Variable/G STATE_DET_AMP			=	100 // Max Amp
	Variable/G STATE_DET_PHASE		=	0	
	
	Variable/G FLR_DET_FREQ			=	220 // MHz
	Variable/G FLR_DET_AMP				=	100 // Max Amp
	Variable/G FLR_DET_PHASE			=	0
	
	String/G	WAVEa_compRF				=	":waveforms:Satellite:satellite_load_20130122_compRF.csv"
	String/G	WAVEa_Quad45				=	":waveforms:Satellite:satellite_load_20130122_Quad45.csv"
	String/G	WAVEa_Ez					=	":waveforms:Satellite:satellite_load_20130122_compEz.csv"
	String/G	WAVEa_Ex					=	":waveforms:Satellite:satellite_load_20130122_compEx.csv"
	String/G	WAVEa_Ey					=	":waveforms:Satellite:satellite_load_20130122_compEyTol.csv"
	String/G	WAVEa_Harm					=	":waveforms:Satellite:satellite_load_20130122_Harmonic.csv"		
	String/G	WAVEa_Hardware			=	":waveforms:Satellite:Satellite_Hardware.csv"
	
	String/G	WAVEb_compRF				=	":waveforms:Satellite:satellite_slot_20130122_compRF.csv"
	String/G	WAVEb_Quad45				=	":waveforms:Satellite:satellite_slot_20130122_Quad45.csv"
	String/G	WAVEb_Ez					=	":waveforms:Satellite:satellite_slot_20130122_compEz.csv"
	String/G	WAVEb_Ex					=	":waveforms:Satellite:satellite_slot_20130122_compEx.csv"
	String/G	WAVEb_Ey					=	":waveforms:Satellite:satellite_slot_20130122_compEyTol.csv"
	String/G	WAVEb_Harm				=	":waveforms:Satellite:satellite_slot_20130122_Harmonic.csv"		
	String/G	WAVEb_Hardware			=	":waveforms:Satellite:Satellite_Hardware.csv"
	
	String/G	WAVEc_Hardware			=	":waveforms:Satellite:Satellite_Hardware_q1_flip.csv"


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
	Make/O/T/N=10 TTLNames									=	{"Delay","Cool","State Detection","Flourescence Detection","Pump","Cool Shutter","LoadShutter","Raman 1", "Raman 2","PMT","935 EO"}			
	Make/O/T/N=3 DDSNames									=	{"Raman 1", "Raman 2","Cool"}
	Make/O/T/N=4 DDSScans									=	{"Duration","Frequency","Amplitude","Phase"}
	Make/O/T/N=3 EONames									=	{"State Detection", "Flourescence Detection"}
	Make/O/T/N=1 EONotDDSNames							=	{"935 EO"}
	Make/O/T/N=3 EONOTDDSSCans							=	{"Duration","EO Frequency","EOAmplitude"}
	Make/O/T/N=6 EOScans									=	{"Duration","AO Frequency","AO Amplitude","AO Phase","EO Frequency","EO Amplitude"}
	Make/O/N=(1024,3)	PulseCreatorWave					=	0
	Make/O/N=(1024,3) dataloaderwave						=	0
	Variable/G TooLong										=	0
	NewPath/O/C/Q/Z SavePath, 								"Z:\\Experiment\\ver.Current\\Sequences\\"
	NewPath/O/C/Q/Z TempPath,									"Z:\\Experiment\\ver.Current\\Settings\\"
	NewPath/O/C/Q/Z TempDataPath,								"Z:\\Experiment\\ver.Current\\Data\\"
	NewPath/O/C/Q/Z TemperPath								"Z:\\Experiment\\ver.Current\\Data\\"
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
	
	
	//Make/O/N=3/T LoadWaveFiles							= {"TestSequence","935Test","PMT Test"}
	Make/O/N=0/T LoadWaveFiles
	
	// Grab all sequences in the folder
	Variable fileIndex = 0
	PathInfo home
	NewPath/O SequencesPath, S_path+"Sequences:"
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
	Make/O/N=7 							COMP_INFO		 = {0,0.5,0,-1.0,0,1,1}
	Make/O/T/N=7 						WAVE_INFOa	 = {WAVEa_compRF, WAVEa_Quad45, WAVEa_Ex, WAVEa_Ey, WAVEa_Ez, WAVEa_Harm, WAVEa_Hardware}
	Make/O/T/N=7 						WAVE_INFOb	 = {WAVEb_compRF, WAVEb_Quad45, WAVEb_Ex, WAVEb_Ey, WAVEb_Ez, WAVEb_Harm, WAVEb_Hardware}
	Make/O/T/N=7 						WAVE_INFOc	 = {WAVEa_compRF, WAVEa_Quad45, WAVEa_Ex, WAVEa_Ey, WAVEa_Ez, WAVEa_Harm, WAVEc_Hardware}
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


Function DC_init()
	NewDataFolder/O/S root:DCVolt
	NewDataFolder/O/S root:DCVolt:temp
	LoadDCWaveMatricies()
//	upPos(Load_Pos,0)
	updateVoltages()
End

Function LoadDCWaveMatricies() // Loads all voltage matricies
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
				break
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

// This function loads in a waveform from the given name
Function/WAVE LoadDCWaveMatrixHelper(filename, outname) //Loads single voltage matrix
	String filename
	String outname
	
	NewDataFolder/O/S root:DCVolt:temp
	
	String matname = "matWave" + outname
	LoadWave/M/O/U={0,0,1,0}/B="N=" + matname + ";" /J/P=home filename
	
	return $matname
EndMacro



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


//--------------------------------------------------------------
//
//                          Windows
//
//--------------------------------------------------------------

Window DCCtrl() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /N=DCCtrl/K=1 /W=(30+0,75+0,30+260,75+260+60) as "Trap DC Voltage Control"
	ModifyPanel cbRGB=(65534,65534,65534)
	SetVariable apos,pos={20,17.5},size={100,20},bodyWidth=60,proc=fieldUpdate,title="A Field"
	SetVariable apos,limits={-inf,inf,.01},value= root:ExpParams:COMP_INFO[0]
	SetVariable bpos,pos={20,47.5},size={100,20},bodyWidth=60,proc=fieldUpdate,title="B Field"
	SetVariable bpos,limits={-inf,inf,.01},value= root:ExpParams:COMP_INFO[1]
	SetVariable cpos,pos={20,77.5},size={100,20},bodyWidth=60,proc=fieldUpdate,title="C Field"
	SetVariable cpos,limits={-inf,inf,.01},value= root:ExpParams:COMP_INFO[2]
	SetVariable dpos,pos={20,77.5+30},size={100,20},bodyWidth=60,proc=fieldUpdate,title="D Field"
	SetVariable dpos,limits={-inf,inf,.01},value= root:ExpParams:COMP_INFO[3]
	SetVariable epos,pos={20,77.5+60},size={100,20},bodyWidth=60,proc=fieldUpdate,title="E Field"
	SetVariable epos,limits={-inf,inf,.01},value= root:ExpParams:COMP_INFO[4]
	SetVariable harmScale,pos={20,107.5+60},size={100,20},bodyWidth=60,proc=fieldUpdate,title="Harm. SF"
	SetVariable harmScale,limits={-inf,inf,.01},value= root:ExpParams:COMP_INFO[5]
	SetVariable globScale,pos={20,137.5+60},size={100,20},bodyWidth=60,proc=fieldUpdate,title="Glob. SF"
	SetVariable globScale,limits={-inf,inf,.01},value= root:ExpParams:COMP_INFO[6]
	SetVariable posIon,pos={20,167.5+60},size={100,20},bodyWidth=60,proc=fieldUpdate,title="Ion Pos."
	SetVariable posIon,limits={-440,inf,1},value= root:ExpParams:CUR_POS
	Button update,pos={135,195+60},size={110,20},proc=Update,title="Update"
	Button settings,pos={135,225+60},size={110,20},proc=openSettings,title="Settings"
	CheckBox liveupdate,pos={46,198+60},size={76,14},proc=LiveUpCheck,title="Live Update"
	CheckBox liveupdate,value= 0,side= 1
EndMacro

Window DCSettings(l,r,t,b) : Panel
	Variable l,r,t,b
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(r+8,t+30,r+8+400,t+30+165+30+70) as "DC Voltage Settings"
	ModifyPanel cbRGB=(65534,65534,65534)
	SetDataFolder root:ExpParams
	Variable/G DC_BANK_VAL = 1
	SetVariable afile,pos={34,17},size={261,18},bodyWidth=185,title="A Voltage File"
	SetVariable afile,value= root:ExpParams:WAVE_INFO[0]
	SetVariable bfile,pos={35,47},size={260,18},bodyWidth=185,title="B Voltage File"
	SetVariable bfile,value= root:ExpParams:WAVE_INFO[1]
	SetVariable cfile,pos={34,77},size={261,18},bodyWidth=185,title="C Voltage File"
	SetVariable cfile,value= root:ExpParams:WAVE_INFO[2]
	SetVariable dfile,pos={34,107},size={261,18},bodyWidth=185,title="D Voltage File"
	SetVariable dfile,value= root:ExpParams:WAVE_INFO[3]
	SetVariable efile,pos={36,137},size={259,18},bodyWidth=185,title="E Voltage File"
	SetVariable efile,value= root:ExpParams:WAVE_INFO[4]
	SetVariable hfile,pos={9,167},size={286,18},bodyWidth=185,title="Harm. Voltage File"
	SetVariable hfile,value= root:ExpParams:WAVE_INFO[5]
	SetVariable wfile,pos={7,197},size={288,18},bodyWidth=185,title="Hardware Map File"
	SetVariable wfile,value= root:ExpParams:WAVE_INFO[6]
	Button aopen,pos={300,15},size={50,20},proc=OpenWaveFile,title="Open"
	Button bopen,pos={300,45},size={50,20},proc=OpenWaveFile,title="Open"
	Button copen,pos={300,75},size={50,20},proc=OpenWaveFile,title="Open"
	Button dopen,pos={300,105},size={50,20},proc=OpenWaveFile,title="Open"
	Button eopen,pos={300,135},size={50,20},proc=OpenWaveFile,title="Open"
	Button hopen,pos={300,165},size={50,20},proc=OpenWaveFile,title="Open"
	Button wopen,pos={300,195},size={50,20},proc=OpenWaveFile,title="Open"
	Button updateFields,pos={137,225},size={135,20},proc=OpenWaveFile,title="Update Field Waves"
	CheckBox abank,pos={285,228},size={25,15},title="A",value= 1,mode=1,proc=DCBankProc
	CheckBox bbank,pos={315,228},size={25,15},title="B",value= 0,mode=1,proc=DCBankProc
	CheckBox cbank,pos={345,228},size={25,15},title="C",value= 0,mode=1,proc=DCBankProc
EndMacro

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

Window Pulse() : Panel
	PauseUpdate; Silent 1		// building window...
	DoWindow /K Pulse
	NewPanel /N=Pulse /K=1 /W=(75,247,409,302) as "Pulse Program"
	ModifyPanel cbRGB=(65534,65534,65534)
	
	PopupMenu Sequence,pos={68,18},size={202,21},bodyWidth=150,proc=PopMenuProc,title="Sequence",mode=1,value=makepopnames()
EndMacro

Function/S makepopnames()
	SetDatafolder Root:ExpParams
	WAVE/T LoadWaveFiles
	
	Make/O/N=0/T LoadWaveFiles
	Variable fileIndex = 0
	PathInfo home
	NewPath/O SequencesPath, S_path+"Sequences:"
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
	
	String names=" "
	Variable i=0

	For(i=0;i<Dimsize(LoadWavefiles,0);i+=1)
		names+=";"+LoadWaveFiles[i]
	EndFor
	Return names

End

Window PulseCreator() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(996,136,1329,186) as "Pulse Creator"
	ModifyPanel cbRGB=(65534,65534,65534)
	Button NewItem,pos={15,16},size={80,20},proc=NewItemPressed,title="New Item",userdata="0" // store num of items in NewItem
	Button DeleteItem,pos={117,16},size={80,20},proc=DeleteItemPressed,title="Delete Item"
	Button SetLoops,pos={219,16},size={80,20},proc=SetLoopsPressed,title="Set Loops"
EndMacro

Window Dataloader() : Panel
	PauseUpdate; Silent 1		// building window...
	DoWindow /K Dataloader
	NewPanel /N=Dataloader /K=1 /W=(75,110,408,210) as "Data Loader"
	ModifyPanel cbRGB=(65534,65534,65534)
	Checkbox SingleVariable, pos={35,15},size={80,20},proc=SingleVariable_proc,title="Single Variable", mode=1
	Checkbox VariableCorrelation, pos={165,15},size={80,20},proc=VariableCorrelation_proc,title="Variable Correlation",mode=1,disable=1
EndMacro


Window OverrideVariables() : Panel
	SetDataFolder root:DDS
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
		
		ddstitle= "TitleBox DDS"+num2str(i)+"Namebox frame=4,fixedSize=1,font=\"Arial\",labelBack=(0,0,0),fColor=(65535,65535,65535),anchor=MC,pos={50,"+num2str(position)+"},size={150,20}, title=\"DDS #"+num2str(i)+"\""
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
	While (i<=3)
	i=1
		Do 
		
		eotitle= "TitleBox EO"+num2str(i)+"Namebox frame=4,fixedSize=1,font=\"Arial\",labelBack=(0,0,0),fColor=(65535,65535,65535),anchor=MC,pos={50,"+num2str(position)+"},size={150,20}, title=\"EO #"+num2str(i)+"\""
		position+=25
		
		eoFreqBox="SetVariable EO"+num2str(i)+"_FREQ_BOX,pos={50,"+num2str(position)+"},size={195,20},bodyWidth=130,proc=EO_wrapper,title=\"EO"+num2str(i)+" Frequency\",font=\"Arial\",limits={2000,7500,1},value= root:ExpParams:DDS_INFO["+num2str(i-1)+"][0]"
		position+=20
		
		eoAmpBox="SetVariable EO"+num2str(i)+"_AMPL_BOX,pos={50,"+num2str(position)+"},size={195,20},bodyWidth=130,proc=EO_wrapper,title=\"EO"+num2str(i)+" Amplitude\",font=\"Arial\",limits={0,1023,1},value= root:ExpParams:DDS_INFO["+num2str(i-1)+"][2]"
		position+=20
		
		eoOverride="Checkbox EO"+num2str(i)+"_Override,pos={50,"+num2str(position)+"},size={195,20},bodyWidth=130,proc=EO_Overridewrapper,title=\"EO "+num2str(i)+" Override\",font=\"Arial\",value=0"

		position+=40
		Execute eotitle
		Execute eoFreqBox
		Execute eoAmpBox
		Execute eoOverride
		i+=1
	While (i<=3)
	

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

