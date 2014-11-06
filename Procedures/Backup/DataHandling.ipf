#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//_____________________________________________________________________________
//
//	dataHandler(expt) creates an Experiment structure based on the current sequence type
//_____________________________________________________________________________
//
function DataHandler(rawData,[init])
	wave rawData
	variable init
	init = paramIsDefault(init) ? 0 : init
	SetDataFolder root:Sequencer:Data
	
	variable i = 1
	for(i=1;i!=9;i+=1)

		WAVE data			= $("data_0"+num2str(i))
		WAVE dataHist	= $("dataHist_0"+num2str(i))
		WAVE dataAvg		= $("dataAvg_0"+num2str(i))
		WAVE dataStd 	= $("dataStd_0"+num2str(i))
		WAVE dataProb	= $("dataProb_0"+num2str(i))
		WAVE dataBiErr	= $("dataBiErr_0"+num2str(i))
		
		variable counts		= 0
		if(init)
		
			//KillWindow DataFrame
			Redimension/N=0 dataHist
			Redimension/N=0 dataAvg
			Redimension/N=0 dataStd
			Redimension/N=0 dataProb
			Redimension/N=0 dataBiErr
			
		Elseif(DimSize(rawData,0)>=i)
			Redimension/N=(DimSize(rawData,1)) data 
			data =rawData[i-1][p]
			//print data
			wavestats/Q data
			
			counts=V_npnts
			
			Histogram/B={0,1,50} data ,dataHist
			
			Redimension/N=(Dimsize(dataAvg,0)+1) dataAvg
			Redimension/N=(Dimsize(dataStd,0)+1) dataStd
			
			dataAvg[(Dimsize(dataAvg,0)-1)] = V_avg
			dataStd[(Dimsize(dataStd,0)-1)] = V_sdev
			
			wavestats/Q/R=[1] dataHist
			
			Redimension/N=(Dimsize(dataProb,0)+1) dataProb
			Redimension/N=(Dimsize(dataBiErr,0)+1) dataBiErr
			
			dataProb[(Dimsize(dataProb,0)-1)] = V_sum/counts
			dataBiErr[(Dimsize(dataBiErr,0)-1)] = sqrt(((V_sum/counts)*(1-(V_sum/counts)))/counts)
		else
			//print "Done with data analysis"
			Break
		endif		
	endfor
end
//_____________________________________________________________________________
//
//	DataDisplay() creates hisograms and probability curves or the data collected.
//_____________________________________________________________________________
//
function DataDisplay()
	SetDataFolder root:Sequencer:Data
	SVAR ScanVarName
	WAVE dataScanVar
	strswitch(ScanVarName)
		case "Frequency":
			ScanVarName	= "Frequency (MHz)"
			//dataScanVar*10^(-6)
			Break
		case "Duration":
			ScanVarName	= "Duration (us)"
	//		dataScanVar	=	dataScanVar*10^-6
			Break
	endswitch
	DoUpdate
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
//	DataFrace() Macro to recreate data frame and the plots within
//_____________________________________________________________________________
//
Window DataFrame() : Panel
//	SetDataFolder root:Sequencer:Data	
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(471,1244,1559,2002) as "Data Frame"
	ModifyPanel cbRGB=(0,0,0)
	ShowInfo/W=DataFrame
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Sequencer:Data:
	Display/W=(12,6,536,376)/HOST=#  dataProb_01 vs dataScanVar
	SetDataFolder fldrSav0
	ModifyGraph mode=3
	ModifyGraph marker=19
	ModifyGraph rgb=(0,43520,65280)
	Label left "Probability"
	SetDataFolder root:Sequencer:Data:
	Label Bottom ScanVarName
	SetDataFolder fldrSav0	
	ErrorBars dataProb_01 Y,wave=(:Sequencer:Data:dataBiErr_01,:Sequencer:Data:dataBiErr_01)
	RenameWindow #,G0
	SetActiveSubwindow ##
	String fldrSav1= GetDataFolder(1)
	SetDataFolder root:Sequencer:Data:
	Display/W=(12,380,536,750)/HOST=#  dataHist_01
	SetDataFolder fldrSav1
	ModifyGraph mode=5
	ModifyGraph hbFill=5
	Label left "Number of Experiments"
	Label bottom "Number of photons"
	RenameWindow #,G1
	SetActiveSubwindow ##
	String fldrSav2= GetDataFolder(1)
	SetDataFolder root:Sequencer:Data:
	Display/W=(540,6,1076,376)/HOST=#  dataAvg_01 vs dataScanVar
	SetDataFolder fldrSav2
	ModifyGraph mode=3
	ModifyGraph marker=19
	Label left "Average Counts"
	SetDataFolder root:Sequencer:Data:
	Label Bottom ScanVarName
	SetDataFolder fldrSav2	
	ErrorBars dataAvg_01 Y,wave=(:Sequencer:Data:dataStd_01,:Sequencer:Data:dataStd_01)
	RenameWindow #,G2
	SetActiveSubwindow ##
	String fldrSav3= GetDataFolder(1)
	SetDataFolder root:Sequencer:Data:
	Edit/W=(540,380,1076,750)/HOST=#  dataProb_01,dataBiErr_01,dataAvg_01,dataStd_01,dataScanVar
	AppendToTable dataHist_01
	ModifyTable format(Point)=1
	ModifyTable statsArea=85
	SetDataFolder fldrSav3
	RenameWindow #,T0
	SetActiveSubwindow ##
EndMacro
