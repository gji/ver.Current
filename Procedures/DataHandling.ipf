#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//_____________________________________________________________________________
//
//	dataHandler(raw data) creates and appends to the data_avg, data_hist, data_prob etc. waves that save counts from multiple digital channels into the files.
//_____________________________________________________________________________
//
function DataHandler(rawData,[init])
	wave rawData                                             // This is the 8 row 2D array of counts in each channel each experiment.
	variable init
	init = paramIsDefault(init) ? 0 : init
	SetDataFolder root:Sequencer:data
	
	
	
	WAVE PMT_wave		= root:ExpParams:PMT_wave
	WAVE NumIon			= NumIonChan
	NVAR MaxHist           // maximum extent of the histogram
	NVAR DiscPoint			= root:sequencer:DiscPoint
	WAVE dataScanVar
	variable i = 1
	variable k
	for(i=1;i!=9;i+=1)

		WAVE data						= $("data_0"+num2str(i))
		WAVE dataHist					= $("dataHist_0"+num2str(i))
		WAVE dataAvg					= $("dataAvg_0"+num2str(i))
		WAVE dataStd 					= $("dataStd_0"+num2str(i))
		WAVE dataProb					= $("dataProb_0"+num2str(i))
		WAVE dataBiErr					= $("dataBiErr_0"+num2str(i))
		WAVE dataBasisFit				= $("dataBasisFit_0"+num2str(i))
		WAVE dataBasisFitError			= $("dataBasisFitError_0"+num2str(i))		
		WAVE dataParity					= $("dataParity_0"+num2str(i))
		WAVE dataParityError			= $("dataParityError_0"+num2str(i))
		WAVE dataPop					= $("dataPop_0"+num2str(i))
		WAVE dataPopError				= $("dataPopError_0"+num2str(i))		
		
//		k= 10*(1+Sin(Pi*2*datascanvar[Dimsize(Datascanvar,0)-1]/datascanvar[0]))
		
		variable counts		= 0
		if(init)
				
			Redimension/N=0 dataHist
			Redimension/N=0 dataAvg
			Redimension/N=0 dataStd
			Redimension/N=0 dataProb
			Redimension/N=0 dataBiErr
			Redimension/N=0 dataBasisFit
			Redimension/N=0 dataBasisFitError			
			Redimension/N=0 dataParity
			Redimension/N=0 dataParityError
			Redimension/N=0 dataPop
			Redimension/N=0 dataPopError			
			
			
		Elseif(DimSize(rawData,0)>=i)
			if(PMT_wave[i])

				Redimension/N=(DimSize(rawData,1)) data 
				data =rawData[i-1][p]
				wavestats/Q data
				
				counts=V_npnts                    // number of experiments that happened or the number of columsns in rawData[i]
				
				Histogram/B={0,1,MaxHist} data,  dataHist           // histogram computed
				Redimension/N=(Dimsize(dataAvg,0)+1) dataAvg    	
				Redimension/N=(Dimsize(dataStd,0)+1) dataStd	
				dataHist=dataHist/counts
				dataAvg[(Dimsize(dataAvg,0)-1)] 	= V_avg			// average computed
				dataStd[(Dimsize(dataStd,0)-1)] 	= V_sdev/counts	// standard error calculated
				
				if(NumIon[i-1]==1)
					Redimension/N=2 dataBasisFit
					Redimension/N=2 dataBasisFitError
					Make/O/T/N=4 T_Constraints
					T_Constraints[0] = {"K0 > 0","K0 < 1.00000 - K1 ","K1 > 0","K1 < 1.00000 - K0"}
					dataBasisFit={0.5,0.5}
					FuncFit/N=1/W=2/Q/NTHR=0 HistOneIon, dataBasisFit,  dataHist /D /C=T_Constraints/E=dataBasisFitError
					dataBasisFit=dataBasisFit/Sum(dataBasisFit)
					Redimension/N=(Dimsize(dataPop,0)+1) dataPop
					Redimension/N=(Dimsize(dataPopError,0)+1) dataPopError
					dataPop[(Dimsize(dataPop,0)-1)] 	=dataBasisFit[1]
					dataPopError[(Dimsize(dataPopError,0)-1)] = dataBasisFitError[1]					
				elseif(NumIon[i-1]==2)
					Redimension/N=3 dataBasisFit
					Redimension/N=3 dataBasisFitError
					Make/O/T/N=6 T_Constraints
					T_Constraints[0] = {"K0 > 0","K0 < 1.00000- K1 - K2","K1 > 0 ","K1 < 1.00000- K0 - K2","K2 > 0 ","K2 < 1.00000- K1 - K0"}
					dataBasisFit={0.25,0.25,0.25}
					FuncFit/N=1/W=2/Q/NTHR=0 HistTwoIon, dataBasisFit,  dataHist /D /C=T_Constraints/E=dataBasisFitError
					dataBasisFit=dataBasisFit/Sum(dataBasisFit)
					Redimension/N=(Dimsize(dataParity,0)+1) dataParity
					Redimension/N=(Dimsize(dataParityError,0)+1) dataParityError
					dataParity[(Dimsize(dataParity,0)-1)] 	=dataBasisFit[2]+ dataBasisFit[0]-dataBasisFit[1]
					dataParityError[(Dimsize(dataParityError,0)-1)] = Sum(dataBasisFitError)	
				endif
			else
				Redimension/N=(DimSize(rawData,1)) data 
				data =rawData[i-1][p]
				data[i-1]=0								// sets the raw date to zeros
				wavestats/Q data
				
				counts=V_npnts
				
				Histogram/B={0,1,MaxHist} data ,dataHist
			
				Redimension/N=(Dimsize(dataAvg,0)+1) dataAvg
				Redimension/N=(Dimsize(dataStd,0)+1) dataStd
				dataHist=dataHist/counts				
				dataAvg[(Dimsize(dataAvg,0)-1)] = V_avg
				dataStd[(Dimsize(dataStd,0)-1)] = V_sdev/counts
			endif
				
				wavestats/Q/R=[DiscPoint] dataHist
				Redimension/N=(Dimsize(dataProb,0)+1) dataProb
				Redimension/N=(Dimsize(dataBiErr,0)+1) dataBiErr
				
				dataProb[(Dimsize(dataProb,0)-1)] = V_sum/counts
				dataBiErr[(Dimsize(dataBiErr,0)-1)] = sqrt(((V_sum/counts)*(1-(V_sum/counts)))/counts)
		else
			Break
		endif		
	endfor
end

//_____________________________________________________________________________
//
//	DataPrefGUI() creates a panel to choose what data to display and process
//_____________________________________________________________________________
//

function DataPrefGUI()
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Sequencer:Data:
	string windows= WinList("DataPref"," ; ","")  // Kill any previous GUI for data preference.
	if	(strlen(windows)>0)
		KillWindow DataPref
	endif
	WAVE numIon 		= root:sequencer:Data:numionchan
	Execute "DataPref()"  // creates the GUI for data preferences.
	DispProc("AvgDisp",1)   // toggles between the check box preferences.
	variable i=1
	string name
	for(i=1;i!=9;i+=1)
		name ="PMT"+num2str(i)+"box"
		if(NumIon[i-1])
			PMTproc(name,1)
			checkbox/Z $name value =1
		else
			PMTproc(name,0)
		endif	
	endfor
	SetDataFolder fldrSav0
end


function AlignPrefGUI()
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Sequencer:AlignmentSweeper:
	string windows= WinList("AlignPref"," ; ","")
	if	(strlen(windows)>0)
		KillWindow AlignPref
	endif
	WAVE numIon 		= root:sequencer:alignmentsweeper:numionchanalign
	Execute "AlignPref()"
	AlignDispProc("AvgDisp",1)
	variable i=1
	string name
	for(i=1;i!=9;i+=1)
		name ="PMT"+num2str(i)+"box"
		if(NumIon[i-1])
			PMTproc(name,1)
			checkbox/Z $name value =1
		else
			PMTproc(name,0)
		endif	
	endfor
	SetDataFolder fldrSav0
	
end



Function SAVEproc(ctrlName,checked): CheckBoxControl
	String ctrlName
	Variable checked
	
	String fldrSav0= GetDataFolder(1)
	Setdatafolder root:ExpParams
	
	NVAR SAVE_01
	NVAR SAVE_02
	NVAR SAVE_03
	
	strswitch(ctrlName)
		case "SaveType1":
				SAVE_01 = checked
				break
		case "SaveType2":
				SAVE_02 = checked
				break
		case "SaveType3":
				SAVE_03 = checked
				break
	endswitch
	Setdatafolder fldrSav0
end
//_____________________________________________________________________________
//
//	DataDisplay() creates hisograms and probability curves or the data collected.
//_____________________________________________________________________________
//
function DataDisplay()
	SetDataFolder root:Sequencer:data
	SVAR ScanVarName
	WAVE dataScanVar
	strswitch(ScanVarName)
		case "Frequency":
			ScanVarName	= "Frequency (MHz)"
			Break
		case "Duration":
			ScanVarName	= "Duration (us)"
			Break
	endswitch
	DoUpdate
	//SetDataFolder root:Sequencer:data:
	variable i=0
	WAVE PMT_wave			=	root:expparams:pmt_wave
	WAVE NumIon				=	root:sequencer:data:NumIonChan
	
	WAVE/T dataAvgPMTchannels					=	root:sequencer:data:dataAvgPMTchannels
	WAVE/T dataStdPMTchannels					=	root:sequencer:data:dataStdPMTchannels
	WAVE/T dataHistPMTchannels				=	root:sequencer:data:dataHistPMTchannels
	WAVE/T dataBiErrPMTchannels				=	root:sequencer:data:dataBiErrPMTchannels
	WAVE/T dataProbPMTchannels				=	root:sequencer:data:dataProbPMTchannels
	WAVE/T dataBasisFitchannels					=	root:sequencer:data:dataBasisFitchannels
	WAVE/T dataBasisFitErrorchannels			=	root:sequencer:data:dataBasisFitErrorchannels
	WAVE/T dataParitychannels					=	root:sequencer:data:dataParitychannels
	WAVE/T dataParityErrorchannels				=	root:sequencer:data:dataParityErrorchannels
	WAVE/T dataPopchannels						=	root:sequencer:data:dataPopchannels
	WAVE/T dataPopErrorchannels				=	root:sequencer:data:dataPopErrorchannels	
	
	Redimension/N=0 dataAvgPMTchannels
	Redimension/N=0 dataStdPMTchannels
	Redimension/N=0 dataHistPMTchannels
	Redimension/N=0 dataBiErrPMTchannels
	Redimension/N=0 dataProbPMTchannels
	Redimension/N=0 dataBasisFitchannels
	Redimension/N=0 dataBasisFitErrorchannels
	Redimension/N=0 dataParitychannels
	Redimension/N=0 dataParityErrorchannels
	Redimension/N=0 dataPopchannels
	Redimension/N=0 dataPopErrorchannels	
	
	SetDataFolder root:Sequencer:data	
	for(i=1;i!=9;i+=1)
		WAVE data					= $("data_0"+num2str(i))
		WAVE dataHist				= $("dataHist_0"+num2str(i))
		WAVE dataAvg				= $("dataAvg_0"+num2str(i))
		WAVE dataStd 				= $("dataStd_0"+num2str(i))
		WAVE dataProb				= $("dataProb_0"+num2str(i))
		WAVE dataBiErr				= $("dataBiErr_0"+num2str(i))
		WAVE dataBasisFit			= $("dataBasisFit_0"+num2str(i))
		WAVE dataBasisFitError		= $("dataBasisFitError_0"+num2str(i))
		WAVE dataParity				= $("dataParity_0"+num2str(i))
		WAVE dataParityError		= $("dataParityError_0"+num2str(i))
		WAVE dataPop				= $("dataPop_0"+num2str(i))
		WAVE dataPopError			= $("dataPopError_0"+num2str(i))
		
		if(PMT_wave[i])
			Redimension/N=(Dimsize(dataAvgPMTchannels,0)+1) dataAvgPMTchannels
			dataAvgPMTchannels[Dimsize(dataAvgPMTchannels,0)-1]						=	"dataAvg_0"+num2str(i)
			
			Redimension/N=(Dimsize(dataStdPMTchannels,0)+1) dataStdPMTchannels
			dataStdPMTchannels[Dimsize(dataStdPMTchannels,0)-1]						=	"dataStd_0"+num2str(i)
			
			Redimension/N=(Dimsize(dataHistPMTchannels,0)+1) dataHistPMTchannels
			dataHistPMTchannels[Dimsize(dataHistPMTchannels,0)-1]					=	"dataHist_0"+num2str(i)
			
			Redimension/N=(Dimsize(dataBiErrPMTchannels,0)+1) dataBiErrPMTchannels
			dataBiErrPMTchannels[Dimsize(dataBiErrPMTchannels,0)-1]					=	"dataBiErr_0"+num2str(i)
			
			Redimension/N=(Dimsize(dataProbPMTchannels,0)+1) dataProbPMTchannels
			dataProbPMTchannels[Dimsize(dataProbPMTchannels,0)-1]					=	"dataProb_0"+num2str(i)

		endif
		if(NumIon[i-1])		
			Redimension/N=(Dimsize(dataBasisFitchannels,0)+1) dataBasisFitchannels
			dataBasisFitchannels[Dimsize(dataBasisFitchannels,0)-1]				=	"dataBasisFit_0"+num2str(i)
			
			Redimension/N=(Dimsize(dataBasisFitErrorchannels,0)+1) dataBasisFitErrorchannels
			dataBasisFitErrorchannels[Dimsize(dataBasisFitErrorchannels,0)-1]	=	"dataBasisFitError_0"+num2str(i)
			
			Redimension/N=(Dimsize(dataPopchannels,0)+1) dataPopchannels
			dataPopchannels[Dimsize(dataPopchannels,0)-1]					=	"datapop_0"+num2str(i)
			
			Redimension/N=(Dimsize(dataPopErrorchannels,0)+1) dataPopErrorchannels
			dataPopErrorchannels[Dimsize(dataPopErrorchannels,0)-1]		=	"dataPopError_0"+num2str(i)
		endif
		if(NumIon[i-1]==2)
			Redimension/N=(Dimsize(dataParitychannels,0)+1) dataParitychannels
			dataParitychannels[Dimsize(dataParitychannels,0)-1]					=	"dataparity_0"+num2str(i)
			
			Redimension/N=(Dimsize(dataParityErrorchannels,0)+1) dataParityErrorchannels
			dataParityErrorchannels[Dimsize(dataParityErrorchannels,0)-1]		=	"dataParityError_0"+num2str(i)
		endif	
		
	endfor
	//Redimension/N=(Dimsize(dataPMTchannels,0)-1) dataPMTchannels
	string windows= WinList("DataFrame"," ; ","")
	if	(strlen(windows)>0)
		KillWindow DataFrame
		Execute "DataFrame()"	
	else
		Execute "DataFrame()"
	endif
	//DoWindow
end

//_____________________________________________________________________________
//
//	DataPref() Macro to recreate data frame and the plots within
//_____________________________________________________________________________
//
Window DataPref() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(309,458,837,686) as "Data Preferences"
	ModifyPanel cbRGB=(48896,65280,57344)
	SetDrawLayer UserBack
	DrawText 12,32,"Digital Inputs to Process"
	DrawText 350,32,"# Ions"
	CheckBox PMT2box,pos={86,43},size={49,15},proc=PMTproc,title="Chan 2",value= 0
	CheckBox PMT1box,pos={23,44},size={49,15},proc=PMTproc,title="Chan 1",value= 0
	CheckBox PMT3box,pos={23,74},size={49,15},proc=PMTproc,title="Chan 3",value= 0
	CheckBox PMT4box,pos={87,74},size={49,15},proc=PMTproc,title="Chan 4",value= 0
	CheckBox PMT6box,pos={87,104},size={49,15},proc=PMTproc,title="Chan 6",value= 0
	CheckBox PMT7box,pos={24,134},size={49,15},proc=PMTproc,title="Chan 7",value= 0
	CheckBox PMT8box,pos={87,135},size={49,15},proc=PMTproc,title="Chan 8",value= 0
	CheckBox PMT5box,pos={24,105},size={49,15},proc=PMTproc,title="Chan 5",value= 0
	CheckBox ProbDisp,pos={160,44},size={88,15},proc=DispProc,title="Display Prob"
	CheckBox ProbDisp,variable= DisplayFlagProb,mode=1,value =0
	CheckBox AvgDisp,pos={160,64},size={81,15},proc=DispProc,title="Display Avg"
	CheckBox AvgDisp,variable= DisplayFlagAvg,mode=1,value=1
	Button Run,pos={413,84},size={100,20},proc=RunProc,title="Run"
	SetVariable MaxHistPoints,pos={140,104},size={147,18},bodyWidth=54,title="Hist Range"
	SetVariable MaxHistPoints,limits={1,1000,1},value= root:Sequencer:data:MaxHist
	SetVariable DiscPointBox,pos={125,124},size={163,18},bodyWidth=54,title="Discriminator"
	SetVariable DiscPointBox,limits={0,1000,1},value= root:Sequencer:DiscPoint
	SetVariable NumIon1,pos={250,44},size={147,18},bodyWidth=54,title="Chan 1"
	SetVariable NumIon1,limits={0,2,1},value= root:Sequencer:data:NumIonChan[0]
	SetVariable NumIon1, disable=2
	SetVariable NumIon2,pos={250,64},size={147,18},bodyWidth=54,title="Chan 2"
	SetVariable NumIon2,limits={0,2,1},value= root:Sequencer:data:NumIonChan[1]
	SetVariable NumIon2, disable=2
	SetVariable NumIon3,pos={250,84},size={147,18},bodyWidth=54,title="Chan 3"
	SetVariable NumIon3,limits={0,2,1},value= root:Sequencer:data:NumIonChan[2]
	SetVariable NumIon3, disable=2
	SetVariable NumIon4,pos={250,104},size={147,18},bodyWidth=54,title="Chan 4"
	SetVariable NumIon4,limits={0,2,1},value= root:Sequencer:data:NumIonChan[3]
	SetVariable NumIon4, disable=2
	SetVariable NumIon5,pos={250,124},size={147,18},bodyWidth=54,title="Chan 5"
	SetVariable NumIon5,limits={0,2,1},value= root:Sequencer:data:NumIonChan[4]
	SetVariable NumIon5, disable=2
	SetVariable NumIon6,pos={250,144},size={147,18},bodyWidth=54,title="Chan 6"
	SetVariable NumIon6,limits={0,2,1},value= root:Sequencer:data:NumIonChan[5]
	SetVariable NumIon6, disable=2
	SetVariable NumIon7,pos={250,164},size={147,18},bodyWidth=54,title="Chan 7"
	SetVariable NumIon7,limits={0,2,1},value= root:Sequencer:data:NumIonChan[6]
	SetVariable NumIon7, disable=2
	SetVariable NumIon8,pos={250,184},size={147,18},bodyWidth=54,title="Chan 8"
	SetVariable NumIon8,limits={0,2,1},value= root:Sequencer:data:NumIonChan[7]
	SetVariable NumIon8, disable=2

EndMacro

Function DispProc(ctrlName,checked): CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR DisplayFlagAvg			=	root:sequencer:Data:DisplayFlagAvg
	NVAR DisplayFlagProb			=	root:sequencer:Data:DisplayFlagProb
	strswitch(ctrlName)
		case "ProbDisp":
			if(checked)
				if(DisplayFlagAvg&&DisplayFlagProb==0)
					DisplayFlagProb	=1
					DisplayFlagAvg	=0
					CheckBox AvgDisp, value=0
				endif	
			endif
			break
		case "AvgDisp":
			if(checked)
				if(DisplayFlagProb&&DisplayFlagAvg==0)
					DisplayFlagProb	=0
					DisplayFlagAvg	=1
					CheckBox ProbDisp, value=0
				endif	
			endif
			break
	endswitch
	DoUpdate
end


//_____________________________________________________________________________
//
//	AlignPref() Macro to recreate data frame and the plots within
//_____________________________________________________________________________
//
Window AlignPref() : Panel
	PauseUpdate; Silent 1		// building window...
	
	NewPanel /W=(309,458,837,686) as "Alignment Sweeper Preferences"
	ModifyPanel cbRGB=(48896,65280,57344)
	SetDrawLayer UserBack
	DrawText 12,32,"Digital Inputs to Process"
	DrawText 350,32,"# Ions"
	CheckBox PMT2box,pos={86,43},size={58,15},proc=PMTproc,title="Chan 2",value= 0
	CheckBox PMT1box,pos={23,44},size={58,15},proc=PMTproc,title="Chan 1",value= 1
	CheckBox PMT3box,pos={23,74},size={58,15},proc=PMTproc,title="Chan 3",value= 0
	CheckBox PMT4box,pos={87,74},size={58,15},proc=PMTproc,title="Chan 4",value= 0
	CheckBox PMT6box,pos={87,104},size={58,15},proc=PMTproc,title="Chan 6",value= 0
	CheckBox PMT7box,pos={24,134},size={58,15},proc=PMTproc,title="Chan 7",value= 0
	CheckBox PMT8box,pos={87,135},size={58,15},proc=PMTproc,title="Chan 8",value= 0
	CheckBox PMT5box,pos={24,105},size={58,15},proc=PMTproc,title="Chan 5",value= 0
	
	CheckBox ProbDisp,pos={160,84},size={88,15},proc=AlignDispProc,title="Display Prob"
	CheckBox ProbDisp,variable= AlignDisplayFlagProb,mode=1
	CheckBox AvgDisp,pos={160,64},size={81,15},proc=alignDispProc,title="Display Avg"
	CheckBox AvgDisp,variable= AlignDisplayFlagAvg,mode=1
	CheckBox TDCDisp,pos={160,44},size={87,15},proc=alignDispProc,title="Display TDC"
	CheckBox TDCDisp,variable= AlignDisplayFlagTDC,mode=1
	SetVariable MaxHistPoints,pos={167,124},size={120,18},bodyWidth=54,title="Hist Range"
	SetVariable MaxHistPoints,limits={1,1000,1},value= root:Sequencer:AlignmentSweeper:AlignMaxHist
	SetVariable DiscPointBox,pos={156,144},size={132,18},bodyWidth=54,title="Discriminator"
	SetVariable DiscPointBox,limits={0,1000,1},value= root:Sequencer:DiscPoint
	
	Button AlignRun,pos={413,84},size={100,20},proc=AlignmentProc,title="Run"
	SetVariable AlignPoints,pos={163,104},size={123,18},bodyWidth=54,title="Window Pts"
	SetVariable AlignPoints,limits={1,1000,1},value= root:Sequencer:AlignmentSweeper:ALIGNSWEEP_POINTS

	SetVariable NumIon1,pos={299,44},size={98,18},bodyWidth=54,title="Chan 1"
	SetVariable NumIon1,limits={0,2,1},value= root:Sequencer:AlignmentSweeper:NumIonChanAlign[0]
	SetVariable NumIon2,pos={299,64},size={98,18},bodyWidth=54,disable=2,title="Chan 2"
	SetVariable NumIon2,limits={0,2,1},value= root:Sequencer:AlignmentSweeper:NumIonChanAlign[1]
	SetVariable NumIon3,pos={299,84},size={98,18},bodyWidth=54,disable=2,title="Chan 3"
	SetVariable NumIon3,limits={0,2,1},value= root:Sequencer:AlignmentSweeper:NumIonChanAlign[2]
	SetVariable NumIon4,pos={299,104},size={98,18},bodyWidth=54,disable=2,title="Chan 4"
	SetVariable NumIon4,limits={0,2,1},value= root:Sequencer:AlignmentSweeper:NumIonChanAlign[3]
	SetVariable NumIon5,pos={299,124},size={98,18},bodyWidth=54,disable=2,title="Chan 5"
	SetVariable NumIon5,limits={0,2,1},value= root:Sequencer:AlignmentSweeper:NumIonChanAlign[4]
	SetVariable NumIon6,pos={299,144},size={98,18},bodyWidth=54,disable=2,title="Chan 6"
	SetVariable NumIon6,limits={0,2,1},value= root:Sequencer:AlignmentSweeper:NumIonChanAlign[5]
	SetVariable NumIon7,pos={299,164},size={98,18},bodyWidth=54,disable=2,title="Chan 7"
	SetVariable NumIon7,limits={0,2,1},value= root:Sequencer:AlignmentSweeper:NumIonChanAlign[6]
	SetVariable NumIon8,pos={299,184},size={98,18},bodyWidth=54,disable=2,title="Chan 8"
	SetVariable NumIon8,limits={0,2,1},value= root:Sequencer:AlignmentSweeper:NumIonChanAlign[7]
EndMacro

Function AlignDispProc(ctrlName,checked): CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR AlignDisplayFlagAvg			=	root:sequencer:alignmentsweeper:AlignDisplayFlagAvg
	NVAR AlignDisplayFlagProb			=	root:sequencer:alignmentsweeper:AlignDisplayFlagProb
	NVAR AlignDisplayFlagTDC			=	root:sequencer:alignmentsweeper:AlignDisplayFlagTDC	
	strswitch(ctrlName)
		case "ProbDisp":
			if(checked)
				if((AlignDisplayFlagAvg+AlignDisplayFlagProb+AlignDisplayFlagTDC)==1)
					AlignDisplayFlagProb	=1
					AlignDisplayFlagAvg	=0
					AlignDisplayFlagTDC	=0
					CheckBox AvgDisp, value=0
					CheckBox TDCDisp, value=0					
				endif	
			endif
			break
		case "AvgDisp":
			if(checked)
				if((AlignDisplayFlagAvg+AlignDisplayFlagProb+AlignDisplayFlagTDC)==1)
					AlignDisplayFlagProb	=0
					AlignDisplayFlagAvg	=1
					AlignDisplayFlagTDC	=0					
					CheckBox ProbDisp, value=0
					CheckBox TDCDisp, value=0						
				endif	
			endif
			break
		case "TDCDisp":
			if(checked)
				if((AlignDisplayFlagAvg+AlignDisplayFlagProb+AlignDisplayFlagTDC)==1)
					AlignDisplayFlagProb	=0
					AlignDisplayFlagAvg	=0
					AlignDisplayFlagTDC	=1					
					CheckBox ProbDisp, value=0
					CheckBox AVGDisp, value=0					
				endif	
			endif
			break
	endswitch
	DoUpdate
end

//_____________________________________________________________________________
//
// SavebasisHistogram() Macro to give user options of saving the last histogram as a basis function
//_____________________________________________________________________________
//
Window SaveBasisHistogram() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1/W=(309,458,837,646) as "SaveBasisHistogram"
	ModifyPanel cbRGB=(48896,65280,57344)
	SetDrawLayer UserBack
	SetDataFolder root:Sequencer:AlignmentSweeper
	DrawText 23,32,"Channel to read"
	DrawText 160,32,"Save As?"
	CheckBox PMT1box,pos={23,44},size={49,15},title="Chan 1",proc=BasisChannelInputProc,value= 0
	CheckBox PMT2box,pos={86,44},size={49,15},title="Chan 2",proc=BasisChannelInputProc,value= 0
	CheckBox PMT3box,pos={23,74},size={49,15},title="Chan 3",proc=BasisChannelInputProc,value= 0
	CheckBox PMT4box,pos={87,74},size={49,15},title="Chan 4",proc=BasisChannelInputProc,value= 0
	CheckBox PMT6box,pos={87,104},size={49,15},title="Chan 6",proc=BasisChannelInputProc,value= 0
	CheckBox PMT7box,pos={24,134},size={49,15},title="Chan 7",proc=BasisChannelInputProc,value= 0
	CheckBox PMT8box,pos={87,135},size={49,15},title="Chan 8",proc=BasisChannelInputProc,value= 0
	CheckBox PMT5box,pos={24,105},size={49,15},title="Chan 5",proc=BasisChannelInputProc,value= 0
	
	CheckBox D,pos={160,44},size={88,15},proc=SaveHistogramCheckedProc,title="Dark"
	CheckBox D,mode=1,value =0
	CheckBox B,pos={160,64},size={81,15},proc=SaveHistogramCheckedProc,title="Bright"
	CheckBox B,mode=1,value=0
	CheckBox DD,pos={160,84},size={88,15},proc=SaveHistogramCheckedProc,title="Dark-Dark"
	CheckBox DD,mode=1,value =0
	CheckBox DB,pos={160,104},size={81,15},proc=SaveHistogramCheckedProc,title="Dark-Bright"
	CheckBox DB,mode=1,value=0
	CheckBox BB,pos={160,124},size={81,15},proc=SaveHistogramCheckedProc,title="Bright-Bright"
	CheckBox BB,mode=1,value=0
	Button DoNotSave,pos={300,44},size={100,20},proc=CloseWindowProc,title="Do Not Save"
EndMacro

Function BasisChannelInputProc(ctrlName,checked): CheckBoxControl
	String ctrlName
	Variable checked
	SetDataFolder root:Sequencer:AlignmentSweeper
	NVAR	BasisPMTinputchannel
	strswitch(ctrlName)
		case "PMT1box":
			if(checked)
				BasisPMTinputchannel =1
				 CheckBox PMT2box, disable=2
				 CheckBox PMT3box, disable=2
				 CheckBox PMT4box, disable=2
				 CheckBox PMT5box, disable=2
				 CheckBox PMT6box, disable=2
				 CheckBox PMT7box, disable=2
				 CheckBox PMT8box, disable=2
				break
			else
				BasisPMTinputchannel =0
				 CheckBox PMT2box, disable=0
				 CheckBox PMT3box, disable=0
				 CheckBox PMT4box, disable=0
				 CheckBox PMT5box, disable=0
				 CheckBox PMT6box, disable=0
				 CheckBox PMT7box, disable=0
				 CheckBox PMT8box, disable=0
				break
			endif
		case "PMT2box":
			if(checked)
				BasisPMTinputchannel =2
				 CheckBox PMT1box, disable=2
				 CheckBox PMT3box, disable=2
				 CheckBox PMT4box, disable=2
				 CheckBox PMT5box, disable=2
				 CheckBox PMT6box, disable=2
				 CheckBox PMT7box, disable=2
				 CheckBox PMT8box, disable=2
				break
			else
				BasisPMTinputchannel =0
				 CheckBox PMT1box, disable=0
				 CheckBox PMT3box, disable=0
				 CheckBox PMT4box, disable=0
				 CheckBox PMT5box, disable=0
				 CheckBox PMT6box, disable=0
				 CheckBox PMT7box, disable=0
				 CheckBox PMT8box, disable=0
				break
			endif
		case "PMT3box":
			if(checked)
				BasisPMTinputchannel =3
				 CheckBox PMT1box, disable=2
				 CheckBox PMT2box, disable=2
				 CheckBox PMT4box, disable=2
				 CheckBox PMT5box, disable=2
				 CheckBox PMT6box, disable=2
				 CheckBox PMT7box, disable=2
				 CheckBox PMT8box, disable=2
				break
			else
				BasisPMTinputchannel =0
				 CheckBox PMT1box, disable=0
				 CheckBox PMT2box, disable=0
				 CheckBox PMT4box, disable=0
				 CheckBox PMT5box, disable=0
				 CheckBox PMT6box, disable=0
				 CheckBox PMT7box, disable=0
				 CheckBox PMT8box, disable=0
				break
			endif
		case "PMT4box":
			if(checked)
				BasisPMTinputchannel =4
				 CheckBox PMT2box, disable=2
				 CheckBox PMT3box, disable=2
				 CheckBox PMT1box, disable=2
				 CheckBox PMT5box, disable=2
				 CheckBox PMT6box, disable=2
				 CheckBox PMT7box, disable=2
				 CheckBox PMT8box, disable=2
				break
			else
				BasisPMTinputchannel =0
				 CheckBox PMT2box, disable=0
				 CheckBox PMT3box, disable=0
				 CheckBox PMT1box, disable=0
				 CheckBox PMT5box, disable=0
				 CheckBox PMT6box, disable=0
				 CheckBox PMT7box, disable=0
				 CheckBox PMT8box, disable=0
				break
			endif
		case "PMT5box": 
			if(checked)
				BasisPMTinputchannel =5
				 CheckBox PMT2box, disable=2
				 CheckBox PMT3box, disable=2
				 CheckBox PMT4box, disable=2
				 CheckBox PMT1box, disable=2
				 CheckBox PMT6box, disable=2
				 CheckBox PMT7box, disable=2
				 CheckBox PMT8box, disable=2
				break
			else
				BasisPMTinputchannel =0
				 CheckBox PMT2box, disable=0
				 CheckBox PMT3box, disable=0
				 CheckBox PMT4box, disable=0
				 CheckBox PMT1box, disable=0
				 CheckBox PMT6box, disable=0
				 CheckBox PMT7box, disable=0
				 CheckBox PMT8box, disable=0
				break
			endif
		case "PMT6box":
			if(checked)
				BasisPMTinputchannel =6
				 CheckBox PMT2box, disable=2
				 CheckBox PMT3box, disable=2
				 CheckBox PMT4box, disable=2
				 CheckBox PMT5box, disable=2
				 CheckBox PMT1box, disable=2
				 CheckBox PMT7box, disable=2
				 CheckBox PMT8box, disable=2
				break
			else
				BasisPMTinputchannel =0
				 CheckBox PMT2box, disable=0
				 CheckBox PMT3box, disable=0
				 CheckBox PMT4box, disable=0
				 CheckBox PMT5box, disable=0
				 CheckBox PMT1box, disable=0
				 CheckBox PMT7box, disable=0
				 CheckBox PMT8box, disable=0
				break
			endif
		case "PMT7box": 
			if(checked)
				BasisPMTinputchannel =7
				 CheckBox PMT2box, disable=2
				 CheckBox PMT3box, disable=2
				 CheckBox PMT4box, disable=2
				 CheckBox PMT5box, disable=2
				 CheckBox PMT6box, disable=2
				 CheckBox PMT1box, disable=2
				 CheckBox PMT8box, disable=2
				break
			else
				BasisPMTinputchannel =0
				 CheckBox PMT2box, disable=0
				 CheckBox PMT3box, disable=0
				 CheckBox PMT4box, disable=0
				 CheckBox PMT5box, disable=0
				 CheckBox PMT6box, disable=0
				 CheckBox PMT1box, disable=0
				 CheckBox PMT8box, disable=0
				break
			endif
		case "PMT8box": 
			if(checked)
				BasisPMTinputchannel =8
				 CheckBox PMT2box, disable=2
				 CheckBox PMT3box, disable=2
				 CheckBox PMT4box, disable=2
				 CheckBox PMT5box, disable=2
				 CheckBox PMT6box, disable=2
				 CheckBox PMT7box, disable=2
				 CheckBox PMT1box, disable=2
				break
			else
				BasisPMTinputchannel =0
				 CheckBox PMT2box, disable=0
				 CheckBox PMT3box, disable=0
				 CheckBox PMT4box, disable=0
				 CheckBox PMT5box, disable=0
				 CheckBox PMT6box, disable=0
				 CheckBox PMT7box, disable=0
				 CheckBox PMT1box, disable=0
				break
			endif
	endswitch

	return 0
End

Function SaveHistogramCheckedProc(ctrlName,checked): CheckBoxControl
	String ctrlName
	Variable checked
	SetDataFolder root:Sequencer:AlignmentSweeper
	NVAR	BasisPMTinputchannel
	Wave 	AlignBasisHistD , AlignBasisHistB  , AlignBasisHistDD , AlignBasisHistDB , AlignBasisHistBB
	
	
	variable channelnumber = BasisPMTinputchannel
	strswitch(ctrlName)
		case "D":
			if(checked)
				Wave temphist = $("alignmentHist_0"+num2str(channelnumber))
				AlignBasisHistD = temphist
				KillWindow SaveBasisHistogram
			endif
			break
		case "B":
			if(checked)
				WAVE temphist = $("alignmentHist_0"+num2str(channelnumber))
				AlignBasisHistB = temphist
				KillWindow SaveBasisHistogram
			endif
			break
		case "DD":
			if(checked)
				WAVE temphist = $("alignmentHist_0"+num2str(channelnumber))
				AlignBasisHistDD = temphist
				KillWindow SaveBasisHistogram
			endif
			break
		case "DB":
			if(checked)
				WAVE temphist = $("alignmentHist_0"+num2str(channelnumber))
				AlignBasisHistDB = temphist
				KillWindow SaveBasisHistogram
			endif
			break
		case "BB":
			if(checked)
				WAVE temphist = $("alignmentHist_0"+num2str(channelnumber))
				AlignBasisHistBB = temphist
				KillWindow SaveBasisHistogram
			endif
			break
	endswitch
	
	return 0 
End

Function CloseWindowProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )	
		case 2: // mouse up
			string windows= WinList("SaveBasisHistogram"," ; ","")
			if	(strlen(windows)>0)
				KillWindow SaveBasisHistogram
			endif

			break
		case -1:
			break
	endswitch
End
//_____________________________________________________________________________
//
// Executed when the step is changed
//_____________________________________________________________________________
//
Function FitData()
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Sequencer:Data
	string windows= WinList("AlignPref"," ; ","")
	if	(strlen(windows)>0)
		KillWindow AlignPref
	endif
	Execute "FitPref()"
//	Setactivesubwindow DataFrame#DataAvgTestName
//	K0 = 5;K1 = 5;K2 = 0.15;K3 = -1.5
//	CurveFit/G/NTHR=0/TBOX=257 sin  root:Sequencer:Data:dataAvg_01 /X=root:Sequencer:Data:dataScanVar /D /F={0.990000, 4}
	SetDataFolder fldrSav0
end


Window FitPref() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(176,407,704,595) as "Fit Preferences"
	ModifyPanel cbRGB=(48896,65280,57344)
//	SetDrawLayer UserBack
//	DrawText 12,32,"Digital Inputs to Process"
//	DrawText 162,31,"Fit Function "
//	CheckBox PMT2box,pos={86,43},size={49,15},proc=PMTproc,title="PMT2",value= 0
//	CheckBox PMT1box,pos={23,44},size={49,15},proc=PMTproc,title="PMT1",value= 0
//	CheckBox PMT3box,pos={23,74},size={49,15},proc=PMTproc,title="PMT3",value= 0
//	CheckBox PMT4box,pos={87,74},size={49,15},proc=PMTproc,title="PMT4",value= 0
//	CheckBox PMT6box,pos={87,104},size={49,15},proc=PMTproc,title="PMT6",value= 0
//	CheckBox PMT7box,pos={24,134},size={49,15},proc=PMTproc,title="PMT7",value= 0
//	CheckBox PMT8box,pos={87,135},size={49,15},proc=PMTproc,title="PMT8",value= 0
//	CheckBox PMT5box,pos={24,105},size={49,15},proc=PMTproc,title="PMT5",value= 0
	Button Fit,pos={413,84},size={100,20},proc=FitProc,title="Fit"
//	CheckBox ProbDisp,pos={160,132},size={88,15},proc=DispProc,title="Display Prob"
//	CheckBox ProbDisp,variable= DisplayFlagProb,mode=1,value=0
//	CheckBox AvgDisp,pos={160,113},size={81,15},proc=DispProc,title="Display Avg"
//	CheckBox AvgDisp,variable= DisplayFlagAvg,mode=1,value=1
//	SetVariable MaxHistPoints,pos={161,65},size={147,18},bodyWidth=54,title="Max Histograms"
//	SetVariable MaxHistPoints,limits={1,1000,1},value= root:Sequencer:Data:MaxHist
//	SetVariable DiscPointBox,pos={145,87},size={163,18},bodyWidth=54,title="Discriminator Point"
//	SetVariable DiscPointBox,limits={0,1000,1},value= root:Sequencer:DiscPoint
//	CheckBox SaveType2,pos={316,61},size={84,15},proc=SAVEproc,title="Save Type 2"
//	CheckBox SaveType2,value= 1
//	CheckBox SaveType1,pos={316,39},size={84,15},proc=SAVEproc,title="Save Type 1"
//	CheckBox SaveType1,value= 1
//	CheckBox SaveType3,pos={316,81},size={84,15},proc=SAVEproc,title="Save Type 3"
//	CheckBox SaveType3,value= 1
EndMacro

Function FitProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	setDatafolder root:ExpParams
	switch( ba.eventCode )	
		case 2: // mouse up
			string windows= WinList("FitPref"," ; ","")
			if	(strlen(windows)>0)
				KillWindow FitPref
			endif
			break
		case -1:
			break
	endswitch	
End

Function FitTypeProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	Variable popNum
	String popStr
	
	SetDataFolder root:Sequencer:Data

End

function AlignSweepDataHandler(rawData,[init])
	wave rawData                                             // This is the 8 row 2D array of counts in each channel each experiment.
	variable init
	init = paramIsDefault(init) ? 0 : init
	SetDataFolder root:Sequencer:AlignmentSweeper
	
	
	
	WAVE PMT_wave		= root:ExpParams:PMT_wave
	WAVE NumIon			= NumIonChanAlign
	NVAR ALIGNSWEEP_POINTS
	NVAR AlignMaxHist           // maximum extent of the histogram
	NVAR DiscPoint			= root:sequencer:DiscPoint
	WAVE dataScanVar
	variable i = 1
	for(i=1;i!=9;i+=1)

		WAVE alignment						= $("alignment_0"+num2str(i))
		WAVE alignmentHist					= $("alignmentHist_0"+num2str(i))
		WAVE alignmentAvg					= $("alignmentAvg_0"+num2str(i))
		WAVE alignmentStd 					= $("alignmentStd_0"+num2str(i))
		WAVE alignmentProb					= $("alignmentProb_0"+num2str(i))
		WAVE alignmentBiErr					= $("alignmentBiErr_0"+num2str(i))
		WAVE alignmentBasisFit				= $("alignmentBasisFit_0"+num2str(i))
		WAVE alignmentBasisFitError			= $("alignmentBasisFitError_0"+num2str(i))		
		WAVE alignmentParity				= $("alignmentParity_0"+num2str(i))
		WAVE alignmentParityError			= $("alignmentParityError_0"+num2str(i))
		WAVE alignmentPop					= $("alignmentPop_0"+num2str(i))
		WAVE alignmentPopError				= $("alignmentPopError_0"+num2str(i))		
		
		
		variable counts		= 0
		if(init)
				
			Redimension/N=0 alignmentHist
			Redimension/N=0 alignmentAvg
			Redimension/N=0 alignmentStd
			Redimension/N=0 alignmentProb
			Redimension/N=0 alignmentBiErr
			Redimension/N=0 alignmentBasisFit
			Redimension/N=0 alignmentBasisFitError			
			Redimension/N=0 alignmentParity
			Redimension/N=0 alignmentParityError
			Redimension/N=0 alignmentPop
			Redimension/N=0 alignmentPopError			
			
			
		Elseif(DimSize(rawData,0)>=i)
			if(PMT_wave[i])

				Redimension/N=(DimSize(rawData,1)) alignment 
				alignment =rawData[i-1][p]
				wavestats/Q alignment
				
				counts=V_npnts                    // number of experiments that happened or the number of columsns in rawData[i]
				
				Histogram/B={0,1,AlignMaxHist} alignment,  alignmentHist           // histogram computed
				
				Redimension/N=(Dimsize(alignmentAvg,0)+1) alignmentAvg    	
				Redimension/N=(Dimsize(alignmentStd,0)+1) alignmentStd	
				alignmentHist=alignmentHist/counts
				alignmentAvg[(Dimsize(alignmentAvg,0)-1)] 	= V_avg		// average computed
				alignmentStd[(Dimsize(alignmentStd,0)-1)] 	= V_sdev/counts	// standard deviation calculated
				
				if(NumIon[i-1]==1)
					Redimension/N=2 alignmentBasisFit
					Redimension/N=2 alignmentBasisFitError
					Make/O/T/N=4 T_Constraints
					T_Constraints[0] = {"K0 > 0","K0 < 1.00000 - K1 ","K1 > 0","K1 < 1.00000 - K0"}
					alignmentBasisFit={0.5,0.5}
					FuncFit/N=1/W=2/Q/NTHR=0 HistOneIon, alignmentBasisFit,  alignmentHist /D /C=T_Constraints/E=alignmentBasisFitError
					alignmentBasisFit=AlignmentBasisFit/Sum(AlignmentBasisFit)
					Redimension/N=(Dimsize(alignmentPop,0)+1) alignmentPop
					Redimension/N=(Dimsize(alignmentPopError,0)+1) alignmentPopError
					alignmentPop[(Dimsize(alignmentPop,0)-1)] 	=alignmentBasisFit[1]
					alignmentPopError[(Dimsize(alignmentPopError,0)-1)] = alignmentBasisFitError[1]						
				elseif(NumIon[i-1]==2)
					Redimension/N=3 alignmentBasisFit
					Redimension/N=3 alignmentBasisFitError
					Make/O/T/N=6 T_Constraints
					T_Constraints[0] = {"K0 > 0","K0 < 1.00000- K1 - K2","K1 > 0 ","K1 < 1.00000- K0 - K2","K2 > 0 ","K2 < 1.00000- K1 - K0"}
					alignmentBasisFit={0.25,0.25,0.25}
					FuncFit/N=1/W=2/Q/NTHR=0 HistTwoIon, alignmentBasisFit,  alignmentHist /D /C=T_Constraints/E=alignmentBasisFitError
					alignmentBasisFit=AlignmentBasisFit/Sum(AlignmentBasisFit)
					Redimension/N=(Dimsize(alignmentParity,0)+1) alignmentParity
					Redimension/N=(Dimsize(alignmentParityError,0)+1) alignmentParityError
					alignmentParity[(Dimsize(alignmentParity,0)-1)] 	=AlignmentBasisFit[2]+ AlignmentBasisFit[0]-AlignmentBasisFit[1]
					alignmentParityError[(Dimsize(alignmentParityError,0)-1)] = Sum(alignmentBasisFitError)
				endif
			else
				Redimension/N=(DimSize(rawData,1)) alignment 
				alignment =rawData[i-1][p]
				alignment[i-1]=0								// sets the raw date to zeros
				wavestats/Q alignment
				
				counts=V_npnts
				
				Histogram/B={0,1,AlignMaxHist} alignment ,alignmentHist
	
				alignmentHist=alignmentHist/counts	
				Redimension/N=(Dimsize(alignmentAvg,0)+1) alignmentAvg
				Redimension/N=(Dimsize(alignmentStd,0)+1) alignmentStd
				
				alignmentAvg[(Dimsize(alignmentAvg,0)-1)] = V_avg
				alignmentStd[(Dimsize(alignmentStd,0)-1)] = V_sdev/counts
			endif
				
				wavestats/Q/R=[DiscPoint] alignmentHist
				Redimension/N=(Dimsize(alignmentProb,0)+1) alignmentProb
				Redimension/N=(Dimsize(alignmentBiErr,0)+1) alignmentBiErr
				
				alignmentProb[(Dimsize(alignmentProb,0)-1)] = V_sum/counts
				alignmentBiErr[(Dimsize(alignmentBiErr,0)-1)] = sqrt(((V_sum/counts)*(1-(V_sum/counts)))/counts)

				if(Dimsize(alignmentAvg,0)>alignsweep_points)
					DeletePoints 0,1,alignmentAvg
					Redimension/N=(alignsweep_points) alignmentAvg
				endif
				if (Dimsize(dataScanVar,0)>alignsweep_points)
					DeletePoints 0,1,dataScanVar
					Redimension/N=(alignsweep_points) dataScanVar
				endif
				if(Dimsize(alignmentStd,0)>alignsweep_points)
					DeletePoints 0,1,alignmentStd
					Redimension/N=(alignsweep_points) alignmentStd
				endif
				if(Dimsize(alignmentProb,0)>alignsweep_points)
					DeletePoints 0,1,alignmentProb
					Redimension/N=(alignsweep_points) alignmentProb
				endif
				if(Dimsize(alignmentBiErr,0)>alignsweep_points)
					DeletePoints 0,1,alignmentBiErr
					Redimension/N=(alignsweep_points) alignmentBiErr
				endif
				if(Dimsize(alignmentParity,0)>alignsweep_points)
					DeletePoints 0,1,alignmentParity
					Redimension/N=(alignsweep_points) alignmentParity
				endif
				if(Dimsize(alignmentParityError,0)>alignsweep_points)
					DeletePoints 0,1,alignmentParityError
					Redimension/N=(alignsweep_points) alignmentParityError
				endif
				if(Dimsize(alignmentPop,0)>alignsweep_points)
					DeletePoints 0,1,alignmentPop
					Redimension/N=(alignsweep_points) alignmentPop
				endif			
				if(Dimsize(alignmentPopError,0)>alignsweep_points)
					DeletePoints 0,1,alignmentPopError
					Redimension/N=(alignsweep_points) alignmentPopError
				endif				
		else
			Break
		endif		
	endfor
end

function AlignDataDisplay()
	SetDataFolder root:Sequencer:AlignmentSweeper
	SVAR ScanVarName
	WAVE dataScanVar
	strswitch(ScanVarName)
		case "Frequency":
			ScanVarName	= "Frequency (MHz)"
			Break
		case "Duration":
			ScanVarName	= "Duration (us)"
			Break
	endswitch
	DoUpdate
	//SetDataFolder root:Sequencer:AlignmentSweeper:
	variable i=0
	WAVE PMT_wave			=	root:expparams:pmt_wave
	WAVE NumIon				=	root:sequencer:AlignmentSweeper:NumIonChanAlign
	
	WAVE/T AlignAvgPMTchannels				=	root:sequencer:alignmentsweeper:AlignAvgPMTchannels
	WAVE/T AlignStdPMTchannels				=	root:sequencer:alignmentsweeper:AlignStdPMTchannels
	WAVE/T AlignHistPMTchannels				=	root:sequencer:alignmentsweeper:AlignHistPMTchannels
	WAVE/T AlignBiErrPMTchannels				=	root:sequencer:alignmentsweeper:AlignBiErrPMTchannels
	WAVE/T AlignProbPMTchannels				=	root:sequencer:alignmentsweeper:AlignProbPMTchannels
	WAVE/T AlignBasisFitchannels				=	root:sequencer:alignmentsweeper:AlignBasisFitchannels
	WAVE/T AlignBasisFitErrorchannels			=	root:sequencer:alignmentsweeper:AlignBasisFitErrorchannels
	WAVE/T AlignParitychannels					=	root:sequencer:alignmentsweeper:AlignParitychannels
	WAVE/T AlignParityErrorchannels				=	root:sequencer:alignmentsweeper:AlignParityErrorchannels
	WAVE/T AlignPopchannels					=	root:sequencer:alignmentsweeper:AlignPopchannels
	WAVE/T AlignPopErrorchannels				=	root:sequencer:alignmentsweeper:AlignPopErrorchannels	
	
	Redimension/N=0 AlignAvgPMTchannels
	Redimension/N=0 AlignStdPMTchannels
	Redimension/N=0 AlignHistPMTchannels
	Redimension/N=0 AlignBiErrPMTchannels
	Redimension/N=0 AlignProbPMTchannels
	Redimension/N=0 AlignBasisFitchannels
	Redimension/N=0 AlignBasisFitErrorchannels
	Redimension/N=0 AlignParitychannels
	Redimension/N=0 AlignParityErrorchannels
	Redimension/N=0 AlignPopchannels
	Redimension/N=0 AlignPopErrorchannels	
	
	SetDataFolder root:Sequencer:AlignmentSweeper	
	for(i=1;i!=9;i+=1)
		WAVE alignment					= $("alignment_0"+num2str(i))
		WAVE alignmentHist				= $("alignmentHist_0"+num2str(i))
		WAVE alignmentAvg				= $("alignmentAvg_0"+num2str(i))
		WAVE alignmentStd 				= $("alignmentStd_0"+num2str(i))
		WAVE alignmentProb				= $("alignmentProb_0"+num2str(i))
		WAVE alignmentBiErr				= $("alignmentBiErr_0"+num2str(i))
		WAVE alignmentBasisFit			= $("alignmentBasisFit_0"+num2str(i))
		WAVE alignmentBasisFitError		= $("alignmentBasisFitError_0"+num2str(i))
		WAVE alignmentParity			= $("alignmentParity_0"+num2str(i))
		WAVE alignmentParityError		= $("alignmentParityError_0"+num2str(i))
		WAVE alignmentPop				= $("alignmentPop_0"+num2str(i))
		WAVE alignmentPopError			= $("alignmentPopError_0"+num2str(i))		
		
		if(PMT_wave[i])
			Redimension/N=(Dimsize(AlignAvgPMTchannels,0)+1) AlignAvgPMTchannels
			AlignAvgPMTchannels[Dimsize(AlignAvgPMTchannels,0)-1]					=	"alignmentAvg_0"+num2str(i)
			
			Redimension/N=(Dimsize(AlignStdPMTchannels,0)+1) AlignStdPMTchannels
			AlignStdPMTchannels[Dimsize(AlignStdPMTchannels,0)-1]					=	"alignmentStd_0"+num2str(i)
			
			Redimension/N=(Dimsize(AlignHistPMTchannels,0)+1) AlignHistPMTchannels
			AlignHistPMTchannels[Dimsize(AlignHistPMTchannels,0)-1]					=	"alignmentHist_0"+num2str(i)
			
			Redimension/N=(Dimsize(AlignBiErrPMTchannels,0)+1) AlignBiErrPMTchannels
			AlignBiErrPMTchannels[Dimsize(AlignBiErrPMTchannels,0)-1]					=	"alignmentBiErr_0"+num2str(i)
			
			Redimension/N=(Dimsize(AlignProbPMTchannels,0)+1) AlignProbPMTchannels
			AlignProbPMTchannels[Dimsize(AlignProbPMTchannels,0)-1]					=	"alignmentProb_0"+num2str(i)

		endif
		if(NumIon[i-1])		
			Redimension/N=(Dimsize(AlignBasisFitchannels,0)+1) AlignBasisFitchannels
			AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1]					=	"alignmentBasisFit_0"+num2str(i)
			
			Redimension/N=(Dimsize(AlignBasisFitErrorchannels,0)+1) AlignBasisFitErrorchannels
			AlignBasisFitErrorchannels[Dimsize(AlignBasisFitErrorchannels,0)-1]			=	"alignmentBasisFitError_0"+num2str(i)
				
			Redimension/N=(Dimsize(AlignPopchannels,0)+1) AlignPopchannels
			AlignPopchannels[Dimsize(AlignPopchannels,0)-1]							=	"alignmentpop_0"+num2str(i)
			
			Redimension/N=(Dimsize(AlignPopErrorchannels,0)+1) AlignPopErrorchannels
			AlignPopErrorchannels[Dimsize(AlignPopErrorchannels,0)-1]					=	"alignmentPopError_0"+num2str(i)			
		endif
		if(NumIon[i-1]==2)
			Redimension/N=(Dimsize(AlignParitychannels,0)+1) AlignParitychannels
			AlignParitychannels[Dimsize(AlignParitychannels,0)-1]						=	"alignmentparity_0"+num2str(i)
			
			Redimension/N=(Dimsize(AlignParityErrorchannels,0)+1) AlignParityErrorchannels
			AlignParityErrorchannels[Dimsize(AlignParityErrorchannels,0)-1]				=	"alignmentParityError_0"+num2str(i)
		endif	
		
	endfor
	//Redimension/N=(Dimsize(AlignPMTchannels,0)-1) AlignPMTchannels
	string windows= WinList("AlignSweepDataFrame"," ; ","")
	if	(strlen(windows)>0)
		KillWindow AlignSweepDataFrame
		Execute "AlignSweepDataFrame()"	
	else
		Execute "AlignSweepDataFrame()"
	endif
	//DoWindow
end

//_____________________________________________________________________________
//
//	AlignmentDataFrame() Macro to recreate data frame and the plots within
//_____________________________________________________________________________
//
Window AlignSweepDataFrame() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1250,1000,1154-71+1250, 1000+768) as " Alignment Sweep Data Frame"
	ModifyPanel cbRGB=(0,0,0)
//	ShowInfo/W=AlignSweepDataFrame
	String fldrSav0= GetDataFolder(1)
	SetDatafolder root:sequencer:alignmentsweeper:
	variable k=0
	make/o/n=(Dimsize(AlignHistPMTchannels,0),3) temp_color
	Variable r, g, b
	if(AlignDisplayFlagProb)
		do
			if(Dimsize(AlignProbPMTchannels,0)==0)
				break
			else
				if(k==0)
					Display/W=(12,6,536,376)/N=AlignProbTestName/HOST=#   $(AlignProbPMTchannels[Dimsize(AlignProbPMTchannels,0)-1])  vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph/W=AlignSweepDataFrame#AlignProbTestName marker=19
					do
						r = 65000*((enoise(1)+1)/2)
						g = 65000*((enoise(1)+1)/2)
						b = 65000*((enoise(1)+1)/2)
					while(r^2 + g^2 + b^2 > 6337500000)
					temp_color[DimSize(AlignAvgPMTchannels,0)-1][0] = r
					temp_color[DimSize(AlignAvgPMTchannels,0)-1][1] = g
					temp_color[DimSize(AlignAvgPMTchannels,0)-1][2] = b
					ModifyGraph rgb ($(AlignProbPMTchannels[Dimsize(AlignProbPMTchannels,0)-1]))=(temp_color[DimSize(AlignProbPMTchannels,0)-1][0],temp_color[DimSize(AlignProbPMTchannels,0)-1][1],temp_color[DimSize(AlignProbPMTchannels,0)-1][2])
					Label left "Probability"
					Label bottom "Sweep Points"
					SetAxis/A/E=1 left
					Label Bottom ScanVarName
					ErrorBars  $(AlignProbPMTchannels[Dimsize(AlignProbPMTchannels,0)-1]) Y,wave=($(AlignBiErrPMTchannels[Dimsize(AlignBiErrPMTchannels,0)-1]),$(AlignBiErrPMTchannels[Dimsize(AlignBiErrPMTchannels,0)-1]))
					k=1
				else
					AppendToGraph/W=AlignSweepDataFrame#AlignProbTestName $(AlignProbPMTchannels[Dimsize(AlignProbPMTchannels,0)-1]) vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph marker=19
					do
						r = 65000*((enoise(1)+1)/2)
						g = 65000*((enoise(1)+1)/2)
						b = 65000*((enoise(1)+1)/2)
					while(r^2 + g^2 + b^2 > 6337500000)
					temp_color[DimSize(AlignAvgPMTchannels,0)-1][0] = r
					temp_color[DimSize(AlignAvgPMTchannels,0)-1][1] = g
					temp_color[DimSize(AlignAvgPMTchannels,0)-1][2] = b
					ModifyGraph rgb ($(AlignProbPMTchannels[Dimsize(AlignProbPMTchannels,0)-1]))=(temp_color[DimSize(AlignProbPMTchannels,0)-1][0],temp_color[DimSize(AlignProbPMTchannels,0)-1][1],temp_color[DimSize(AlignProbPMTchannels,0)-1][2])
					ErrorBars $(AlignProbPMTchannels[Dimsize(AlignProbPMTchannels,0)-1]) Y,wave=($(AlignBiErrPMTchannels[Dimsize(AlignBiErrPMTchannels,0)-1]),$(AlignBiErrPMTchannels[Dimsize(AlignBiErrPMTchannels,0)-1]))
				endif
				DeletePoints (DimSize(AlignProbPMTchannels,0)-1),1,AlignProbPMTchannels
				DeletePoints (DimSize(AlignStdPMTchannels,0)-1),1,AlignStdPMTchannels
				DeletePoints (DimSize(AlignBiErrPMTchannels,0)-1),1,AlignBiErrPMTchannels
			endif
		while(Dimsize(AlignProbPMTchannels,0))
		SetActiveSubwindow ##
	endif
	k=0
	if(AlignDisplayFlagAvg)
		do
			if(Dimsize(AlignAvgPMTchannels,0)==0)
				break
			else
				if(k==0)
					Display/W=(12,6,536,376)/N=AlignAvgTestName/HOST=#   $(AlignAvgPMTchannels[Dimsize(AlignAvgPMTchannels,0)-1])  vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph/W=AlignSweepDataFrame#AlignAvgTestName marker=19
					do
						r = 65000*((enoise(1)+1)/2)
						g = 65000*((enoise(1)+1)/2)
						b = 65000*((enoise(1)+1)/2)
					while(r^2 + g^2 + b^2 > 6337500000)
					temp_color[DimSize(AlignAvgPMTchannels,0)-1][0] = r
					temp_color[DimSize(AlignAvgPMTchannels,0)-1][1] = g
					temp_color[DimSize(AlignAvgPMTchannels,0)-1][2] = b
					ModifyGraph rgb ($(AlignAvgPMTchannels[Dimsize(AlignAvgPMTchannels,0)-1]))=(temp_color[DimSize(AlignAvgPMTchannels,0)-1][0],temp_color[DimSize(AlignAvgPMTchannels,0)-1][1],temp_color[DimSize(AlignAvgPMTchannels,0)-1][2])
					Label left "Average Counts"
					Label bottom "Sweep Points"
					Legend
					SetAxis/A/E=1 left
					Label Bottom ScanVarName
					ErrorBars  $(AlignAvgPMTchannels[Dimsize(AlignAvgPMTchannels,0)-1]) Y,wave=($(AlignStdPMTchannels[Dimsize(AlignStdPMTchannels,0)-1]),$(AlignStdPMTchannels[Dimsize(AlignStdPMTchannels,0)-1]))
					k=1
				else
					AppendToGraph/W=AlignSweepDataFrame#AlignAvgTestName $(AlignAvgPMTchannels[Dimsize(AlignAvgPMTchannels,0)-1]) vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph marker=19
					do
						r = 65000*((enoise(1)+1)/2)
						g = 65000*((enoise(1)+1)/2)
						b = 65000*((enoise(1)+1)/2)
					while(r^2 + g^2 + b^2 > 6337500000)
					temp_color[DimSize(AlignAvgPMTchannels,0)-1][0] = r
					temp_color[DimSize(AlignAvgPMTchannels,0)-1][1] = g
					temp_color[DimSize(AlignAvgPMTchannels,0)-1][2] = b
					ModifyGraph rgb ($(AlignAvgPMTchannels[Dimsize(AlignAvgPMTchannels,0)-1]))=(temp_color[DimSize(AlignAvgPMTchannels,0)-1][0],temp_color[DimSize(AlignAvgPMTchannels,0)-1][1],temp_color[DimSize(AlignAvgPMTchannels,0)-1][2])
					ErrorBars $(AlignAvgPMTchannels[Dimsize(AlignAvgPMTchannels,0)-1]) Y,wave=($(AlignStdPMTchannels[Dimsize(AlignStdPMTchannels,0)-1]),$(AlignStdPMTchannels[Dimsize(AlignStdPMTchannels,0)-1]))
				endif
				DeletePoints (DimSize(AlignAvgPMTchannels,0)-1),1,AlignAvgPMTchannels
				DeletePoints (DimSize(AlignStdPMTchannels,0)-1),1,AlignStdPMTchannels
			endif
		while(Dimsize(AlignAvgPMTchannels,0))
		SetActiveSubwindow ##
	endif

	k=0
	do
		if(Dimsize(AlignHistPMTchannels,0)==0)
			break
		else
			if(k==0)
				Display/W=(546,5,1070,375)/N=AlignHistTestName/HOST=#   $(AlignHistPMTchannels[Dimsize(AlignHistPMTchannels,0)-1])
				ModifyGraph mode=5
				ModifyGraph hbFill=5	
				ModifyGraph rgb ($(AlignHistPMTchannels[Dimsize(AlignHistPMTchannels,0)-1]))=(temp_color[DimSize(AlignHistPMTchannels,0)-1][0],temp_color[DimSize(AlignHistPMTchannels,0)-1][1],temp_color[DimSize(AlignHistPMTchannels,0)-1][2])
				//SetAxis left 0,1
				Label left "Number of Experiments"
				Label bottom "Number of photons"
				Legend			
				k=1
			else
				AppendToGraph/W=AlignSweepDataFrame#AlignHistTestName $(AlignHistPMTchannels[Dimsize(AlignHistPMTchannels,0)-1])
				ModifyGraph mode=5
				ModifyGraph hbFill=5
				ModifyGraph rgb ($(AlignHistPMTchannels[Dimsize(AlignHistPMTchannels,0)-1]))=(temp_color[DimSize(AlignHistPMTchannels,0)-1][0],temp_color[DimSize(AlignHistPMTchannels,0)-1][1],temp_color[DimSize(AlignHistPMTchannels,0)-1][2])			
			endif
			DeletePoints (DimSize(AlignHistPMTchannels,0)-1),1,AlignHistPMTchannels
		endif
	while(Dimsize(AlignHistPMTchannels,0))
	SetActiveSubwindow ##
	k=0
	do
		if(Dimsize(AlignParitychannels,0)||Dimsize(AlignPopchannels,0)==0)
			break
		else
			if(k==0)
				if(NumIonChanAlign[splitdatastring(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1])-1]==1)
					Display/W=(12,381,536,751)/N=AlignPopTestName/HOST=#   $(AlignPopchannels[Dimsize(AlignPopchannels,0)-1]) vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph marker =19				
	//				ModifyGraph hbFill=5	
					ModifyGraph rgb ($(AlignPopchannels[Dimsize(AlignPopchannels,0)-1]))=(temp_color[DimSize(AlignPopchannels,0)-1][0],temp_color[DimSize(AlignPopchannels,0)-1][1],temp_color[DimSize(AlignPopchannels,0)-1][2])
					ErrorBars/T=2/L=2  $(AlignPopchannels[Dimsize(AlignPopchannels,0)-1]) Y,wave=($(AlignPopErrorchannels[Dimsize(AlignPopErrorchannels,0)-1]),$(AlignPopErrorchannels[Dimsize(AlignPopErrorchannels,0)-1]))	
					//SetAxis left 0,1
					Label left "Parity"
	//				Label bottom ""
					Legend			
					k=1
				endif
				if(NumIonChanAlign[splitdatastring(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1])-1]==2)
					Display/W=(12,381,536,751)/N=AlignParityTestName/HOST=#   $(AlignParitychannels[Dimsize(AlignParitychannels,0)-1]) vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph marker =19				
	//				ModifyGraph hbFill=5	
					ModifyGraph rgb ($(AlignParitychannels[Dimsize(AlignParitychannels,0)-1]))=(temp_color[DimSize(AlignParitychannels,0)-1][0],temp_color[DimSize(AlignParitychannels,0)-1][1],temp_color[DimSize(AlignParitychannels,0)-1][2])
					ErrorBars/T=2/L=2  $(AlignParitychannels[Dimsize(AlignParitychannels,0)-1]) Y,wave=($(AlignParityErrorchannels[Dimsize(AlignParityErrorchannels,0)-1]),$(AlignParityErrorchannels[Dimsize(AlignParityErrorchannels,0)-1]))	
					//SetAxis left 0,1
					Label left " Bright Population"
	//				Label bottom ""
					Legend			
					k=1
				endif
			else
				if(NumIonChanAlign[splitdatastring(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1])-1]==1)
					AppendToGraph/W=AlignSweepDataFrame#AlignPopTestName $(AlignPopchannels[Dimsize(AlignPopchannels,0)-1]) vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph marker =19
	//				ModifyGraph hbFill=5
					ModifyGraph rgb ($(AlignPopchannels[Dimsize(AlignPopchannels,0)-1]))=(temp_color[DimSize(AlignPopchannels,0)-1][0],temp_color[DimSize(AlignPopchannels,0)-1][1],temp_color[DimSize(AlignPopchannels,0)-1][2])			
					ErrorBars/T=2/L=2  $(AlignPopchannels[Dimsize(AlignPopchannels,0)-1]) Y,wave=($(AlignPopErrorchannels[Dimsize(AlignPopErrorchannels,0)-1]),$(AlignPopErrorchannels[Dimsize(AlignPopErrorchannels,0)-1]))	
				endif
				if(NumIonChanAlign[splitdatastring(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1])-1]==2)
					AppendToGraph/W=AlignSweepDataFrame#AlignParityTestName $(AlignParitychannels[Dimsize(AlignParitychannels,0)-1]) vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph marker =19
	//				ModifyGraph hbFill=5
					ModifyGraph rgb ($(AlignParitychannels[Dimsize(AlignParitychannels,0)-1]))=(temp_color[DimSize(AlignParitychannels,0)-1][0],temp_color[DimSize(AlignParitychannels,0)-1][1],temp_color[DimSize(AlignParitychannels,0)-1][2])			
					ErrorBars/T=2/L=2  $(AlignParitychannels[Dimsize(AlignParitychannels,0)-1]) Y,wave=($(AlignParityErrorchannels[Dimsize(AlignParityErrorchannels,0)-1]),$(AlignParityErrorchannels[Dimsize(AlignParityErrorchannels,0)-1]))	
				endif
			endif
			if(NumIonChanAlign[splitdatastring(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1])-1]==1)
				if(DimSize(AlignPopchannels,0)!=0)
					DeletePoints (DimSize(AlignPopchannels,0)-1),1,AlignPopchannels	
				endif
			endif
			if(NumIonChanAlign[splitdatastring(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1])-1]==2)
				DeletePoints (DimSize(AlignParitychannels,0)-1),1,AlignParitychannels
			endif
		endif
	while(Dimsize(AlignParitychannels,0))
	SetActiveSubwindow ##
	k=0
	do
		if(Dimsize(AlignBasisFitchannels,0)==0)
			break
		else
			if(k==0)
				Display/W=(546,381,1070,751)/N=AlignBasisFitTestName/HOST=#   $(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1])
				ModifyGraph mode=5
				ModifyGraph hbFill=5	
				ModifyGraph rgb ($(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1]))=(temp_color[DimSize(AlignBasisFitchannels,0)-1][0],temp_color[DimSize(AlignBasisFitchannels,0)-1][1],temp_color[DimSize(AlignBasisFitchannels,0)-1][2])
				ModifyGraph offset={-0.5,0}
				ModifyGraph manTick(bottom)={1,1,0,0},manMinor(bottom)={0,0}
				ErrorBars/T=2/L=2  $(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1]) Y,wave=($(AlignBasisFitErrorchannels[Dimsize(AlignBasisFitErrorchannels,0)-1]),$(AlignBasisFitErrorchannels[Dimsize(AlignBasisFitErrorchannels,0)-1]))			
				SetAxis left 0,1
				Label left "Populations"
				Label bottom "Number of Bright Ions"
				Legend
			//	SetActiveSubwindow ##
				if(NumIonChanAlign[splitdatastring(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1])-1]==1)
					CheckDisplayed/W=AlignSweepDataFrame#AlignHistTestName alignBasisHistB
					if(V_Flag==0)
						AppendToGraph/W=AlignSweepDataFrame#AlignHistTestName alignBasisHistB
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName mode(alignBasisHistB)=6
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lsize(alignBasisHistB)=2
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lstyle(AlignBasisHistB)=1
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName rgb (alignBasisHistB)=(temp_color[DimSize(AlignBasisFitchannels,0)-1][0],temp_color[DimSize(AlignBasisFitchannels,0)-1][1],temp_color[DimSize(AlignBasisFitchannels,0)-1][2])				
						
						AppendToGraph/W=AlignSweepDataFrame#AlignHistTestName alignBasisHistD					
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName mode(alignBasisHistD)=6
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lsize(alignBasisHistD)=2
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lstyle(AlignBasisHistD)=2
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName rgb (alignBasisHistD)=(temp_color[DimSize(AlignBasisFitchannels,0)-1][0],temp_color[DimSize(AlignBasisFitchannels,0)-1][1],temp_color[DimSize(AlignBasisFitchannels,0)-1][2])				
					endif
				endif
				if(NumIonChanAlign[splitdatastring(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1])-1]==2)
					CheckDisplayed/W=AlignSweepDataFrame#AlignHistTestName alignBasisHistBB
					if(V_Flag==0)
						AppendToGraph/W=AlignSweepDataFrame#AlignHistTestName alignBasisHistBB
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName mode(alignBasisHistBB)=6
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lsize(alignBasisHistBB)=2
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lstyle(AlignBasisHistBB)=3
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName rgb (alignBasisHistBB)=(temp_color[DimSize(AlignBasisFitchannels,0)-1][0],temp_color[DimSize(AlignBasisFitchannels,0)-1][1],temp_color[DimSize(AlignBasisFitchannels,0)-1][2])
						
						AppendToGraph/W=AlignSweepDataFrame#AlignHistTestName alignBasisHistDB					
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName mode(alignBasisHistDB)=6
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lsize(alignBasisHistDB)=2
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lstyle(AlignBasisHistDB)=4						
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName rgb (alignBasisHistDB)=(temp_color[DimSize(AlignBasisFitchannels,0)-1][0],temp_color[DimSize(AlignBasisFitchannels,0)-1][1],temp_color[DimSize(AlignBasisFitchannels,0)-1][2])
						
						AppendToGraph/W=AlignSweepDataFrame#AlignHistTestName alignBasisHistDD					
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName mode(alignBasisHistDD)=6
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lsize(alignBasisHistDD)=2
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lstyle(AlignBasisHistDD)=5
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName rgb (alignBasisHistDD)=(temp_color[DimSize(AlignBasisFitchannels,0)-1][0],temp_color[DimSize(AlignBasisFitchannels,0)-1][1],temp_color[DimSize(AlignBasisFitchannels,0)-1][2])
					endif
				endif	
				//SetActiveSubwindow ##
				k=1
			else
		//		SetActiveSubwindow ##
				AppendToGraph/W=AlignSweepDataFrame#AlignBasisFitTestName $(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1])
				ModifyGraph mode=5
				ModifyGraph hbFill=5
				ModifyGraph offset={-0.5,0}
				ModifyGraph manTick(bottom)={1,1,0,0},manMinor(bottom)={0,0}				
				ModifyGraph rgb ($(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1]))=(temp_color[DimSize(AlignBasisFitchannels,0)-1][0],temp_color[DimSize(AlignBasisFitchannels,0)-1][1],temp_color[DimSize(AlignBasisFitchannels,0)-1][2])
				ErrorBars/T=2/L=2  $(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1]) Y,wave=($(AlignBasisFitErrorchannels[Dimsize(AlignBasisFitErrorchannels,0)-1]),$(AlignBasisFitErrorchannels[Dimsize(AlignBasisFitErrorchannels,0)-1]))	
				if(NumIonChanAlign[splitdatastring(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1])-1]==1)
					CheckDisplayed/W=AlignSweepDataFrame#AlignHistTestName alignBasisHistB
					if(V_Flag==0)
						AppendToGraph/W=AlignSweepDataFrame#AlignHistTestName alignBasisHistB
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName mode(alignBasisHistB)=6
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lsize(alignBasisHistB)=2
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lstyle(AlignBasisHistB)=1
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName rgb (alignBasisHistB)=(temp_color[DimSize(AlignBasisFitchannels,0)-1][0],temp_color[DimSize(AlignBasisFitchannels,0)-1][1],temp_color[DimSize(AlignBasisFitchannels,0)-1][2])				
						
						AppendToGraph/W=AlignSweepDataFrame#AlignHistTestName alignBasisHistD					
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName mode(alignBasisHistD)=6
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lsize(alignBasisHistD)=2
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lstyle(AlignBasisHistD)=2				
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName rgb (alignBasisHistD)=(temp_color[DimSize(AlignBasisFitchannels,0)-1][0],temp_color[DimSize(AlignBasisFitchannels,0)-1][1],temp_color[DimSize(AlignBasisFitchannels,0)-1][2])				
					endif
				endif
				if(NumIonChanAlign[splitdatastring(AlignBasisFitchannels[Dimsize(AlignBasisFitchannels,0)-1])-1]==2)
					CheckDisplayed/W=AlignSweepDataFrame#AlignHistTestName alignBasisHistBB
					if(V_Flag==0)
						AppendToGraph/W=AlignSweepDataFrame#AlignHistTestName alignBasisHistBB
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName mode(alignBasisHistBB)=6
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lsize(alignBasisHistBB)=2
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lstyle(AlignBasisHistBB)=3
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName rgb (alignBasisHistBB)=(temp_color[DimSize(AlignBasisFitchannels,0)-1][0],temp_color[DimSize(AlignBasisFitchannels,0)-1][1],temp_color[DimSize(AlignBasisFitchannels,0)-1][2])
						
						AppendToGraph/W=AlignSweepDataFrame#AlignHistTestName alignBasisHistDB					
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName mode(alignBasisHistDB)=6
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lsize(alignBasisHistDB)=2
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lstyle(AlignBasisHistDB)=4
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName rgb (alignBasisHistDB)=(temp_color[DimSize(AlignBasisFitchannels,0)-1][0],temp_color[DimSize(AlignBasisFitchannels,0)-1][1],temp_color[DimSize(AlignBasisFitchannels,0)-1][2])
						
						AppendToGraph/W=AlignSweepDataFrame#AlignHistTestName alignBasisHistDD					
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName mode(alignBasisHistDD)=6
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lsize(alignBasisHistDD)=2
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName lstyle(AlignBasisHistDD)=5				
						ModifyGraph/W=AlignSweepDataFrame#AlignHistTestName rgb (alignBasisHistDD)=(temp_color[DimSize(AlignBasisFitchannels,0)-1][0],temp_color[DimSize(AlignBasisFitchannels,0)-1][1],temp_color[DimSize(AlignBasisFitchannels,0)-1][2])
					endif
				endif
				//SetActiveSubwindow ##
			endif
			DeletePoints (DimSize(AlignBasisFitchannels,0)-1),1,AlignBasisFitchannels
		endif
	while(Dimsize(AlignBasisFitchannels,0))
//	SetActiveSubwindow ##
	SetDatafolder fldrSav0
EndMacro
//_____________________________________________________________________________
//
//	DataFrame() Macro to recreate data frame and the plots within OLD
//_____________________________________________________________________________
//
Window DataFrame() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1250,1000,1154-71+1250, 1000+768) as "Data Frame"
	ModifyPanel cbRGB=(0,0,0)
//	ShowInfo/W=DataFrame
	String fldrSav0= GetDataFolder(1)
	SetDatafolder root:sequencer:Data:
	variable k=0, r, g, b
	make/o/n=(Dimsize(DataHistPMTchannels,0),3) temp_color
	if(DataDisplayFlagProb)
		do
			if(Dimsize(DataProbPMTchannels,0)==0)
				break
			else
				if(k==0)
					Display/W=(12,6,536,376)/N=DataProbTestName/HOST=#   $(DataProbPMTchannels[Dimsize(DataProbPMTchannels,0)-1])  vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph/W=DataFrame#DataProbTestName marker=19
					do
						r = 65000*((enoise(1)+1)/2)
						g = 65000*((enoise(1)+1)/2)
						b = 65000*((enoise(1)+1)/2)
					while(r^2 + g^2 + b^2 > 6337500000)
					temp_color[DimSize(DataAvgPMTchannels,0)-1][0] = r
					temp_color[DimSize(DataAvgPMTchannels,0)-1][1] = g
					temp_color[DimSize(DataAvgPMTchannels,0)-1][2] = b
					ModifyGraph rgb ($(DataProbPMTchannels[Dimsize(DataProbPMTchannels,0)-1]))=(temp_color[DimSize(DataProbPMTchannels,0)-1][0],temp_color[DimSize(DataProbPMTchannels,0)-1][1],temp_color[DimSize(DataProbPMTchannels,0)-1][2])
					Label left "Probability"
					Label bottom "Sweep Points"
					SetAxis/A/E=1 left
					Label Bottom ScanVarName
					ErrorBars  $(DataProbPMTchannels[Dimsize(DataProbPMTchannels,0)-1]) Y,wave=($(DataBiErrPMTchannels[Dimsize(DataBiErrPMTchannels,0)-1]),$(DataBiErrPMTchannels[Dimsize(DataBiErrPMTchannels,0)-1]))
					k=1
				else
					AppendToGraph/W=DataFrame#DataProbTestName $(DataProbPMTchannels[Dimsize(DataProbPMTchannels,0)-1]) vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph marker=19
					do
						r = 65000*((enoise(1)+1)/2)
						g = 65000*((enoise(1)+1)/2)
						b = 65000*((enoise(1)+1)/2)
					while(r^2 + g^2 + b^2 > 6337500000)
					temp_color[DimSize(DataAvgPMTchannels,0)-1][0] = r
					temp_color[DimSize(DataAvgPMTchannels,0)-1][1] = g
					temp_color[DimSize(DataAvgPMTchannels,0)-1][2] = b
					ModifyGraph rgb ($(DataProbPMTchannels[Dimsize(DataProbPMTchannels,0)-1]))=(temp_color[DimSize(DataProbPMTchannels,0)-1][0],temp_color[DimSize(DataProbPMTchannels,0)-1][1],temp_color[DimSize(DataProbPMTchannels,0)-1][2])
					ErrorBars $(DataProbPMTchannels[Dimsize(DataProbPMTchannels,0)-1]) Y,wave=($(DataBiErrPMTchannels[Dimsize(DataBiErrPMTchannels,0)-1]),$(DataBiErrPMTchannels[Dimsize(DataBiErrPMTchannels,0)-1]))
				endif
				DeletePoints (DimSize(DataProbPMTchannels,0)-1),1,DataProbPMTchannels
				DeletePoints (DimSize(DataStdPMTchannels,0)-1),1,DataStdPMTchannels
				DeletePoints (DimSize(DataBiErrPMTchannels,0)-1),1,DataBiErrPMTchannels
			endif
		while(Dimsize(DataProbPMTchannels,0))
		SetActiveSubwindow ##
	endif
	k=0
	if(DataDisplayFlagAvg)
		do
			if(Dimsize(DataAvgPMTchannels,0)==0)
				break
			else
				if(k==0)
					Display/W=(12,6,536,376)/N=DataAvgTestName/HOST=#   $(DataAvgPMTchannels[Dimsize(DataAvgPMTchannels,0)-1])  vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph/W=DataFrame#DataAvgTestName marker=19
					do
						r = 65000*((enoise(1)+1)/2)
						g = 65000*((enoise(1)+1)/2)
						b = 65000*((enoise(1)+1)/2)
					while(r^2 + g^2 + b^2 > 6337500000)
					temp_color[DimSize(DataAvgPMTchannels,0)-1][0] = r
					temp_color[DimSize(DataAvgPMTchannels,0)-1][1] = g
					temp_color[DimSize(DataAvgPMTchannels,0)-1][2] = b
					ModifyGraph rgb ($(DataAvgPMTchannels[Dimsize(DataAvgPMTchannels,0)-1]))=(temp_color[DimSize(DataAvgPMTchannels,0)-1][0],temp_color[DimSize(DataAvgPMTchannels,0)-1][1],temp_color[DimSize(DataAvgPMTchannels,0)-1][2])
					Label left "Average Counts"
					Label bottom "Sweep Points"
					Legend
					SetAxis/A/E=1 left
					Label Bottom ScanVarName
					ErrorBars  $(DataAvgPMTchannels[Dimsize(DataAvgPMTchannels,0)-1]) Y,wave=($(DataStdPMTchannels[Dimsize(DataStdPMTchannels,0)-1]),$(DataStdPMTchannels[Dimsize(DataStdPMTchannels,0)-1]))
					k=1
				else
					AppendToGraph/W=DataFrame#DataAvgTestName $(DataAvgPMTchannels[Dimsize(DataAvgPMTchannels,0)-1]) vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph marker=19
					do
						r = 65000*((enoise(1)+1)/2)
						g = 65000*((enoise(1)+1)/2)
						b = 65000*((enoise(1)+1)/2)
					while(r^2 + g^2 + b^2 > 6337500000)
					temp_color[DimSize(DataAvgPMTchannels,0)-1][0] = r
					temp_color[DimSize(DataAvgPMTchannels,0)-1][1] = g
					temp_color[DimSize(DataAvgPMTchannels,0)-1][2] = b
					ModifyGraph rgb ($(DataAvgPMTchannels[Dimsize(DataAvgPMTchannels,0)-1]))=(temp_color[DimSize(DataAvgPMTchannels,0)-1][0],temp_color[DimSize(DataAvgPMTchannels,0)-1][1],temp_color[DimSize(DataAvgPMTchannels,0)-1][2])
					ErrorBars $(DataAvgPMTchannels[Dimsize(DataAvgPMTchannels,0)-1]) Y,wave=($(DataStdPMTchannels[Dimsize(DataStdPMTchannels,0)-1]),$(DataStdPMTchannels[Dimsize(DataStdPMTchannels,0)-1]))
				endif
				DeletePoints (DimSize(DataAvgPMTchannels,0)-1),1,DataAvgPMTchannels
				DeletePoints (DimSize(DataStdPMTchannels,0)-1),1,DataStdPMTchannels
			endif
		while(Dimsize(DataAvgPMTchannels,0))
		SetActiveSubwindow ##
	endif

	k=0
	do
		if(Dimsize(DataHistPMTchannels,0)==0)
			break
		else
			if(k==0)
				Display/W=(546,5,1070,375)/N=DataHistTestName/HOST=#   $(DataHistPMTchannels[Dimsize(DataHistPMTchannels,0)-1])
				ModifyGraph mode=5
				ModifyGraph hbFill=5	
				ModifyGraph rgb ($(DataHistPMTchannels[Dimsize(DataHistPMTchannels,0)-1]))=(temp_color[DimSize(DataHistPMTchannels,0)-1][0],temp_color[DimSize(DataHistPMTchannels,0)-1][1],temp_color[DimSize(DataHistPMTchannels,0)-1][2])
				//SetAxis left 0,1
				Label left "Number of Experiments"
				Label bottom "Number of photons"
				Legend			
				k=1
			else
				AppendToGraph/W=DataFrame#DataHistTestName $(DataHistPMTchannels[Dimsize(DataHistPMTchannels,0)-1])
				ModifyGraph mode=5
				ModifyGraph hbFill=5
				ModifyGraph rgb ($(DataHistPMTchannels[Dimsize(DataHistPMTchannels,0)-1]))=(temp_color[DimSize(DataHistPMTchannels,0)-1][0],temp_color[DimSize(DataHistPMTchannels,0)-1][1],temp_color[DimSize(DataHistPMTchannels,0)-1][2])			
			endif
			DeletePoints (DimSize(DataHistPMTchannels,0)-1),1,DataHistPMTchannels
		endif
	while(Dimsize(DataHistPMTchannels,0))
	SetActiveSubwindow ##
	k=0
	do
		if(Dimsize(DataParitychannels,0)||Dimsize(DataPopchannels,0)==0)
			break
		else
			if(k==0)
				if(NumIonChan[splitdatastring(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1])-1]==1)
					Display/W=(12,381,536,751)/N=DataPopTestName/HOST=#   $(DataPopchannels[Dimsize(DataPopchannels,0)-1]) vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph marker =19				
	//				ModifyGraph hbFill=5	
					ModifyGraph rgb ($(DataPopchannels[Dimsize(DataPopchannels,0)-1]))=(temp_color[DimSize(DataPopchannels,0)-1][0],temp_color[DimSize(DataPopchannels,0)-1][1],temp_color[DimSize(DataPopchannels,0)-1][2])
					ErrorBars/T=2/L=2  $(DataPopchannels[Dimsize(DataPopchannels,0)-1]) Y,wave=($(DataPopErrorchannels[Dimsize(DataPopErrorchannels,0)-1]),$(DataPopErrorchannels[Dimsize(DataPopErrorchannels,0)-1]))	
					//SetAxis left 0,1
					Label left "Parity"
	//				Label bottom ""
					Legend			
					k=1
				endif
				if(NumIonChan[splitdatastring(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1])-1]==2)
					Display/W=(12,381,536,751)/N=DataParityTestName/HOST=#   $(DataParitychannels[Dimsize(DataParitychannels,0)-1]) vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph marker =19				
	//				ModifyGraph hbFill=5	
					ModifyGraph rgb ($(DataParitychannels[Dimsize(DataParitychannels,0)-1]))=(temp_color[DimSize(DataParitychannels,0)-1][0],temp_color[DimSize(DataParitychannels,0)-1][1],temp_color[DimSize(DataParitychannels,0)-1][2])
					ErrorBars/T=2/L=2  $(DataParitychannels[Dimsize(DataParitychannels,0)-1]) Y,wave=($(DataParityErrorchannels[Dimsize(DataParityErrorchannels,0)-1]),$(DataParityErrorchannels[Dimsize(DataParityErrorchannels,0)-1]))	
					//SetAxis left 0,1
					Label left " Bright Population"
	//				Label bottom ""
					Legend			
					k=1
				endif
			else
				if(NumIonChan[splitdatastring(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1])-1]==1)
					AppendToGraph/W=DataFrame#DataPopTestName $(DataPopchannels[Dimsize(DataPopchannels,0)-1]) vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph marker =19
	//				ModifyGraph hbFill=5
					ModifyGraph rgb ($(DataPopchannels[Dimsize(DataPopchannels,0)-1]))=(temp_color[DimSize(DataPopchannels,0)-1][0],temp_color[DimSize(DataPopchannels,0)-1][1],temp_color[DimSize(DataPopchannels,0)-1][2])			
					ErrorBars/T=2/L=2  $(DataPopchannels[Dimsize(DataPopchannels,0)-1]) Y,wave=($(DataPopErrorchannels[Dimsize(DataPopErrorchannels,0)-1]),$(DataPopErrorchannels[Dimsize(DataPopErrorchannels,0)-1]))	
				endif
				if(NumIonChan[splitdatastring(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1])-1]==2)
					AppendToGraph/W=DataFrame#DataParityTestName $(DataParitychannels[Dimsize(DataParitychannels,0)-1]) vs dataScanVar
					ModifyGraph mode=3
					ModifyGraph marker =19
	//				ModifyGraph hbFill=5
					ModifyGraph rgb ($(DataParitychannels[Dimsize(DataParitychannels,0)-1]))=(temp_color[DimSize(DataParitychannels,0)-1][0],temp_color[DimSize(DataParitychannels,0)-1][1],temp_color[DimSize(DataParitychannels,0)-1][2])			
					ErrorBars/T=2/L=2  $(DataParitychannels[Dimsize(DataParitychannels,0)-1]) Y,wave=($(DataParityErrorchannels[Dimsize(DataParityErrorchannels,0)-1]),$(DataParityErrorchannels[Dimsize(DataParityErrorchannels,0)-1]))	
				endif
			endif
			if(NumIonChan[splitdatastring(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1])-1]==1)
				if(DimSize(DataPopchannels,0)!=0)
					DeletePoints (DimSize(DataPopchannels,0)-1),1,DataPopchannels	
				endif
			endif
			if(NumIonChan[splitdatastring(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1])-1]==2)
				DeletePoints (DimSize(DataParitychannels,0)-1),1,DataParitychannels
			endif
		endif
	while(Dimsize(DataParitychannels,0))
	SetActiveSubwindow ##
	k=0
	do
		if(Dimsize(DataBasisFitchannels,0)==0)
			break
		else
			if(k==0)
				Display/W=(546,381,1070,751)/N=DataBasisFitTestName/HOST=#   $(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1])
				ModifyGraph mode=5
				ModifyGraph hbFill=5	
				ModifyGraph rgb ($(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1]))=(temp_color[DimSize(DataBasisFitchannels,0)-1][0],temp_color[DimSize(DataBasisFitchannels,0)-1][1],temp_color[DimSize(DataBasisFitchannels,0)-1][2])
				ModifyGraph offset={-0.5,0}
				ModifyGraph manTick(bottom)={1,1,0,0},manMinor(bottom)={0,0}
				ErrorBars/T=2/L=2  $(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1]) Y,wave=($(DataBasisFitErrorchannels[Dimsize(DataBasisFitErrorchannels,0)-1]),$(DataBasisFitErrorchannels[Dimsize(DataBasisFitErrorchannels,0)-1]))			
				SetAxis left 0,1
				Label left "Populations"
				Label bottom "Number of Bright Ions"
				Legend
			//	SetActiveSubwindow ##
				if(NumIonChan[splitdatastring(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1])-1]==1)
					CheckDisplayed/W=DataFrame#DataHistTestName  root:sequencer:alignmentsweeper:AlignBasisHistB
					if(V_Flag==0)
						AppendToGraph/W=DataFrame#DataHistTestName root:sequencer:alignmentsweeper:AlignBasisHistB
						ModifyGraph/W=DataFrame#DataHistTestName mode(AlignBasisHistB)=6
						ModifyGraph/W=DataFrame#DataHistTestName lsize(AlignBasisHistB)=2
						ModifyGraph/W=DataFrame#DataHistTestName lstyle(AlignBasisHistB)=1
						ModifyGraph/W=DataFrame#DataHistTestName rgb (AlignBasisHistB)=(temp_color[DimSize(DataBasisFitchannels,0)-1][0],temp_color[DimSize(DataBasisFitchannels,0)-1][1],temp_color[DimSize(DataBasisFitchannels,0)-1][2])				
						
						AppendToGraph/W=DataFrame#DataHistTestName root:sequencer:alignmentsweeper:AlignBasisHistD					
						ModifyGraph/W=DataFrame#DataHistTestName mode(AlignBasisHistD	)=6
						ModifyGraph/W=DataFrame#DataHistTestName lsize(AlignBasisHistD)=2
						ModifyGraph/W=DataFrame#DataHistTestName lstyle(AlignBasisHistD)=2
						ModifyGraph/W=DataFrame#DataHistTestName rgb (AlignBasisHistD	)=(temp_color[DimSize(DataBasisFitchannels,0)-1][0],temp_color[DimSize(DataBasisFitchannels,0)-1][1],temp_color[DimSize(DataBasisFitchannels,0)-1][2])				
					endif
				endif
				if(NumIonChan[splitdatastring(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1])-1]==2)
					CheckDisplayed/W=DataFrame#DataHistTestName root:sequencer:alignmentsweeper:AlignBasisHistBB
					if(V_Flag==0)
						AppendToGraph/W=DataFrame#DataHistTestName root:sequencer:alignmentsweeper:AlignBasisHistBB
						ModifyGraph/W=DataFrame#DataHistTestName mode(AlignBasisHistBB)=6
						ModifyGraph/W=DataFrame#DataHistTestName lsize(AlignBasisHistBB)=2
						ModifyGraph/W=DataFrame#DataHistTestName lstyle(AlignBasisHistBB)=3
						ModifyGraph/W=DataFrame#DataHistTestName rgb (AlignBasisHistBB)=(temp_color[DimSize(DataBasisFitchannels,0)-1][0],temp_color[DimSize(DataBasisFitchannels,0)-1][1],temp_color[DimSize(DataBasisFitchannels,0)-1][2])
						
						AppendToGraph/W=DataFrame#DataHistTestName root:sequencer:alignmentsweeper:AlignBasisHistDB					
						ModifyGraph/W=DataFrame#DataHistTestName mode(AlignBasisHistDB)=6
						ModifyGraph/W=DataFrame#DataHistTestName lsize(AlignBasisHistDB)=2
						ModifyGraph/W=DataFrame#DataHistTestName lstyle(AlignBasisHistDB)=4						
						ModifyGraph/W=DataFrame#DataHistTestName rgb (AlignBasisHistDB)=(temp_color[DimSize(DataBasisFitchannels,0)-1][0],temp_color[DimSize(DataBasisFitchannels,0)-1][1],temp_color[DimSize(DataBasisFitchannels,0)-1][2])
						
						AppendToGraph/W=DataFrame#DataHistTestName root:sequencer:alignmentsweeper:AlignBasisHistDD					
						ModifyGraph/W=DataFrame#DataHistTestName mode(AlignBasisHistDD)=6
						ModifyGraph/W=DataFrame#DataHistTestName lsize(AlignBasisHistDD)=2
						ModifyGraph/W=DataFrame#DataHistTestName lstyle(AlignBasisHistDD)=5
						ModifyGraph/W=DataFrame#DataHistTestName rgb (AlignBasisHistDD)=(temp_color[DimSize(DataBasisFitchannels,0)-1][0],temp_color[DimSize(DataBasisFitchannels,0)-1][1],temp_color[DimSize(DataBasisFitchannels,0)-1][2])
					endif
				endif	
				//SetActiveSubwindow ##
				k=1
			else
		//		SetActiveSubwindow ##
				AppendToGraph/W=DataFrame#DataBasisFitTestName $(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1])
				ModifyGraph mode=5
				ModifyGraph hbFill=5
				ModifyGraph offset={-0.5,0}
				ModifyGraph manTick(bottom)={1,1,0,0},manMinor(bottom)={0,0}				
				ModifyGraph rgb ($(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1]))=(temp_color[DimSize(DataBasisFitchannels,0)-1][0],temp_color[DimSize(DataBasisFitchannels,0)-1][1],temp_color[DimSize(DataBasisFitchannels,0)-1][2])
				ErrorBars/T=2/L=2  $(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1]) Y,wave=($(DataBasisFitErrorchannels[Dimsize(DataBasisFitErrorchannels,0)-1]),$(DataBasisFitErrorchannels[Dimsize(DataBasisFitErrorchannels,0)-1]))	
				if(NumIonChan[splitdatastring(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1])-1]==1)
					CheckDisplayed/W=DataFrame#DataHistTestName root:sequencer:alignmentsweeper:AlignBasisHistB
					if(V_Flag==0)
						AppendToGraph/W=DataFrame#DataHistTestName root:sequencer:alignmentsweeper:AlignBasisHistB
						ModifyGraph/W=DataFrame#DataHistTestName mode(AlignBasisHistB)=6
						ModifyGraph/W=DataFrame#DataHistTestName lsize(AlignBasisHistB)=2
						ModifyGraph/W=DataFrame#DataHistTestName lstyle(AlignBasisHistB)=1
						ModifyGraph/W=DataFrame#DataHistTestName rgb (AlignBasisHistB)=(temp_color[DimSize(DataBasisFitchannels,0)-1][0],temp_color[DimSize(DataBasisFitchannels,0)-1][1],temp_color[DimSize(DataBasisFitchannels,0)-1][2])				
						
						AppendToGraph/W=DataFrame#DataHistTestName root:sequencer:alignmentsweeper:AlignBasisHistD					
						ModifyGraph/W=DataFrame#DataHistTestName mode(AlignBasisHistD	)=6
						ModifyGraph/W=DataFrame#DataHistTestName lsize(AlignBasisHistD)=2
						ModifyGraph/W=DataFrame#DataHistTestName lstyle(AlignBasisHistD)=2
						ModifyGraph/W=DataFrame#DataHistTestName rgb (AlignBasisHistD	)=(temp_color[DimSize(DataBasisFitchannels,0)-1][0],temp_color[DimSize(DataBasisFitchannels,0)-1][1],temp_color[DimSize(DataBasisFitchannels,0)-1][2])				
					endif
				endif
				if(NumIonChan[splitdatastring(DataBasisFitchannels[Dimsize(DataBasisFitchannels,0)-1])-1]==2)
					CheckDisplayed/W=DataFrame#DataHistTestName root:sequencer:alignmentsweeper:AlignBasisHistBB
					if(V_Flag==0)
						AppendToGraph/W=DataFrame#DataHistTestName root:sequencer:alignmentsweeper:AlignBasisHistBB
						ModifyGraph/W=DataFrame#DataHistTestName mode(AlignBasisHistBB)=6
						ModifyGraph/W=DataFrame#DataHistTestName lsize(AlignBasisHistBB)=2
						ModifyGraph/W=DataFrame#DataHistTestName lstyle(AlignBasisHistBB)=3
						ModifyGraph/W=DataFrame#DataHistTestName rgb (AlignBasisHistBB)=(temp_color[DimSize(DataBasisFitchannels,0)-1][0],temp_color[DimSize(DataBasisFitchannels,0)-1][1],temp_color[DimSize(DataBasisFitchannels,0)-1][2])
						
						AppendToGraph/W=DataFrame#DataHistTestName root:sequencer:alignmentsweeper:AlignBasisHistDB					
						ModifyGraph/W=DataFrame#DataHistTestName mode(AlignBasisHistDB)=6
						ModifyGraph/W=DataFrame#DataHistTestName lsize(AlignBasisHistDB)=2
						ModifyGraph/W=DataFrame#DataHistTestName lstyle(AlignBasisHistDB)=4						
						ModifyGraph/W=DataFrame#DataHistTestName rgb (AlignBasisHistDB)=(temp_color[DimSize(DataBasisFitchannels,0)-1][0],temp_color[DimSize(DataBasisFitchannels,0)-1][1],temp_color[DimSize(DataBasisFitchannels,0)-1][2])
						
						AppendToGraph/W=DataFrame#DataHistTestName root:sequencer:alignmentsweeper:AlignBasisHistDD					
						ModifyGraph/W=DataFrame#DataHistTestName mode(AlignBasisHistDD)=6
						ModifyGraph/W=DataFrame#DataHistTestName lsize(AlignBasisHistDD)=2
						ModifyGraph/W=DataFrame#DataHistTestName lstyle(AlignBasisHistDD)=5
						ModifyGraph/W=DataFrame#DataHistTestName rgb (AlignBasisHistDD)=(temp_color[DimSize(DataBasisFitchannels,0)-1][0],temp_color[DimSize(DataBasisFitchannels,0)-1][1],temp_color[DimSize(DataBasisFitchannels,0)-1][2])
					endif
				endif
				//SetActiveSubwindow ##
			endif
			DeletePoints (DimSize(DataBasisFitchannels,0)-1),1,DataBasisFitchannels
		endif
	while(Dimsize(DataBasisFitchannels,0))
//	SetActiveSubwindow ##
	SetDatafolder fldrSav0
EndMacro
