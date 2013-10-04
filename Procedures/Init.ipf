#pragma rtGlobals=1		// Use modern global access method.

Macro Exp_Init()

// Fills appropriate waves and variables	
	Param_Init()
	DC_Init()
	Seq_init()
	
// Creates Windows	
	DCCtrl()	
	DDS_Control()
EndMacro

Function Param_Init()
	NewDataFolder/O/S root:ExpParams

	Variable/G LIVE_UP					= 	0
	Variable/G CUR_POS					= 	LOAD_POS		
	
	Variable/G Delay						=	TTL_00
	Variable/G COOL						=	TTL_01
	Variable/G STATE_DET				=	TTL_02
	Variable/G FLR_DET					=	TTL_04|TTL_01
	Variable/G PUMP						=	TTL_02|TTL_03
	Variable/G COOL_SHTR				=	TTL_05
	Variable/G LOAD_SHTR				=	TTL_06
	Variable/G RAMAN1					=	TTL_07
	Variable/G RAMAN2					=	TTL_08
	Variable/G PMT						=	DI_01	// PMT might be gated, might need to add a TTL pulse here
	
	Variable/G COOL_FREQ				= 	200 // MHz
	Variable/G COOL_AMP				=	1023 // Max Amp
	Variable/G COOL_PHASE				=	0 	
	
	Variable/G STATE_DET_FREQ			=	220 // MHz
	Variable/G STATE_DET_AMP			=	1023 // Max Amp
	Variable/G STATE_DET_PHASE		=	0	
	
	Variable/G FLR_DET_FREQ			=	220 // MHz
	Variable/G FLR_DET_AMP			=	1023 // Max Amp
	Variable/G FLR_DET_PHASE			=	0
	
	String/G	WAVE_Ez					=	":waveforms:Symmetric_Ez.csv"
	String/G	WAVE_Ex					=	":waveforms:Symmetric_Ex.csv"
	String/G	WAVE_Ey					=	":waveforms:Symmetric_Ey.csv"
	String/G	WAVE_Harm				=	":waveforms:Symmetric_Harmonic.csv"		
	String/G	WAVE_Hardware				=	":waveforms:Symmetric_Hardware.csv"
	
	Make/O/N=(DDS_Channels,DDS_Params) 	DDS_INFO
	Make/O/N=4 							COMP_INFO		 = {0,0,0,1,1}
	Make/O/T/N=4 							WAVE_INFO		 = {WAVE_Ez, WAVE_Ex, WAVE_Ey, WAVE_Harm}
	
	LoadWave/M/K=2/U={0,0,1,0}/O/B="N=HARDWARE_MAP;" /J/P=home WAVE_Hardware				
	
					//Variables for Pulse Program
	Variable/G SequenceCurrent				=	0
	Variable/G VerticalButtonPosition			=	16
	Variable/G VerticalLoopPosition			=	16
	Variable/G StepNum					=	0
	Variable/G GroupNumber					=	0
	Variable/G GroupError						= 	0
	Make/O/N=10 NameWave					=	{DELAY,COOL,STATE_DET,FLR_DET,PUMP,COOL_SHTR,LOAD_SHTR,RAMAN1,RAMAN2,PMT}
	Make/O/T/N=10 TTLNames				=	{"Delay","Cool","State Detection","Flourescence Detection","Pump","Cool Shutter","LoadShutter","Raman 1", "Raman 2","PMT"}			
	Make/O/N=(1024,3)	PulseCreatorWave
	Variable/G TooLong						=	0
	NewPath/O SavePath, "E:\\Experiment\\ver.Daniel\\Sequences\\"
	Make/O/N=(1024,3)	LoadedWave1		//= LoadWave/D/H/J/M/P=SavePath/T/W/A "WATH.dat"
	Variable/G TotalScan						=	0
	Variable/G FixScanOrder					=	0
	Variable/G GroupMultiplier					=	1
	Make/O/N=(1024,2) PulseSequence
	Make/O/N=1024 TimeSequence
	
	
	
	Variable j,i
	for(i=0;i!=(DDS_Channels); i+=1)
		switch(i)
			case COOL_CNL:
				For(j=0; j!=(DDS_Params); j+=1)	
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
				For(j=0; j!=(DDS_Params); j+=1)	
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
				For(j=0; j!=(DDS_Params); j+=1)	
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
				For(j=0; j!=(DDS_Params); j+=1)	
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

Function LoadDCWaveMatricies() //Loads all voltage matricies
	SetDataFolder root:DCVolt
	
	WAVE COMP_INFO			=	root:ExpParams:COMP_INFO
	WAVE/T WAVE_INFO		=	root:ExpParams:WAVE_INFO
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
	Make/O/N=(NUM_ELECT)	RAW_VOLTAGES
	Make/O/N=96 	OUT_VOLTAGES
	Make/T/O/N=12	CMDS	
	
	
	
	
	for(i=0; i<DimSize(COMP_INFO,0); i+=1)
		SetDataFolder root:DCVolt:temp
		WAVE t = LoadDCWaveMatrixHelper(WAVE_INFO[i], num2str(i))
		Make/O/N=(DimSize(t,0),NUM_ELECT+1) ::$("mat"+num2str(i)) //Extra row for indicies
		WAVE out = ::$("mat"+num2str(i))
		for(k=0; k<DimSize(t,0);k+=1)
			out[k][0] = t[k][0]
			for(j=1;j<NUM_ELECT+1;j+=1)
				out[k][j]=0	
			endfor
		endfor
		for(j=1; j<DimSize(t,1);j+=1)
			FindValue/TEXT=GetDimLabel(t,1,j) HARDWARE_MAP //Stores into V_Value
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

Window DCSettings(l,r,t,b) : Panel
	Variable l,r,t,b
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(r+8,t+30,r+8+400,t+30+165) as "DC Voltage Settings"
	ModifyPanel cbRGB=(65534,65534,65534)
	SetVariable zfile,pos={100,17.5},size={195,20},bodyWidth=185,title="Z Voltage File"
	SetVariable zfile,value= root:ExpParams:WAVE_INFO[0]
	SetVariable xfile,pos={100,47.5},size={195,20},bodyWidth=185,title="X Voltage File"
	SetVariable xfile,value= root:ExpParams:WAVE_INFO[1]
	SetVariable yfile,pos={100,77.5},size={195,20},bodyWidth=185,title="Y Voltage File"
	SetVariable yfile,value= root:ExpParams:WAVE_INFO[2]
	SetVariable hfile,pos={100,107.5},size={195,20},bodyWidth=185,title="Harm. Voltage File"
	SetVariable hfile,value= root:ExpParams:WAVE_INFO[3]
	Button zopen,pos={300,15},size={50,20},proc=OpenWaveFile,title="Open"
	Button xopen,pos={300,45},size={50,20},proc=OpenWaveFile,title="Open"
	Button yopen,pos={300,75},size={50,20},proc=OpenWaveFile,title="Open"
	Button hopen,pos={300,105},size={50,20},proc=OpenWaveFile,title="Open"
	Button updateFields,pos={137.5,135},size={135,20},proc=OpenWaveFile,title="Update Field Waves"
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