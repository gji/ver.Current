#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Macro InitializePMT()
	SetupPMTFiles()
	pmtPanel()
EndMacro

function SetupPMTFiles()
	NewDataFolder /O/S root:PMT
	SetDataFolder root:PMT
	
	Variable/G pmtstarted = 0
	Variable/G tdcstarted = 0
	Variable/G pmt_stor_loc = 0
end

Window pmtPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1464,1297,1580,1373) as "PMT Control"
	ModifyPanel cbRGB=(65280,59904,48896)
	Button pmtStat,pos={18,9},size={81,18},proc=PMTStart,title="Start PMT"
	Button tdcStat,pos={18,36},size={81,18},proc=TDCStart,title="Start TDC"
	ToolsGrid snap=1,visible=1
EndMacro

// t is in ms
function/WAVE pmtData(t, reps)
	Variable t
	Variable reps
	
	SetDatafolder root:ExpParams
	NVAR Mask
	SetDataFolder root:PMT
	Make/O/D pmt_cmd = {{Mask, 0x01000000 | Mask, Mask}, {5, t*50, 5}}
	
	sendSequence(pmt_cmd)
	sleep/s 0.5
	
	return runSequence(reps, recmask = 0x01000000)
end

function GetPMTData(s)
	STRUCT WMBackgroundStruct &s
	
	SetDataFolder root:PMT
	Variable reps =300 // sets the size of out which is made in PMTstart
	Wave counts_hist
	Wave avg_counts
	Wave out
	NVAR pmt_stor_loc
	
	if(avg_counts[299]>=0)
		//out=out+1
		DeletePoints 0,1, avg_counts
		Redimension/N=300 avg_counts
	endif
	
	
	Wave out_temp = pmtData(500, reps) // First arg. is integration time in us, second arg. is reps
	//counts[] = out[p]	
	SetDataFolder root:PMT
	out	= out_temp
	
	avg_counts[299]	= Mean(out)
	Histogram/B={0,1,100} out,counts_hist
	
	return 0
end

Function PMTStart(ctrlName) : ButtonControl
	String ctrlName
	SetDataFolder root:PMT
	SVAR seq_port=root:ExpParams:SEQ_PORT
	
	string seq_p=SEQ_PORT
	NVAR pmtstarted
	
	if(pmtstarted == 1)
		pmtstarted = 0
		
	//	VDT2/P=$seq_p killio
	//	VDT2/P=$seq_p abort
		VDTClosePort2 $seq_p
		CtrlNamedBackground PMT_task, stop
		KillWindow PMTCNT
		KillWindow PMTAVGCNT
		Button pmtstat win=pmtPanel, title="Start PMT"
	else
		pmtstarted = 1
		make/n=300/o out
		Make/N=100/O counts
		counts = 0
		Make/N=100/O counts_hist
		Display/K=1/N=PMTCNT counts_hist
		ModifyGraph mode=6
		Make/N=300/O avg_counts
		Display/K=1/N=PMTAVGCNT avg_counts
		ModifyGraph mode=3
		VDT2/P=$seq_p baud=230400,stopbits=2,killio
		VDTOpenPort2 $seq_p
		VDTOperationsPort2 $seq_p
		if(ComCheck()==0)
		else
			print "Error Writing to "+seq_p
			return -1
		endif
		CtrlNamedBackground PMT_task, period=60, proc=GetPMTData
		CtrlNamedBackground PMT_task, start
		Button pmtstat win=pmtPanel, title="Stop PMT"
	endif
End

Function TDCStart(ctrlName) : ButtonControl
	String ctrlName
	SetDataFolder root:PMT
	
	NVAR tdcstarted
	if(tdcstarted == 1)
		tdcstarted = 0
		Button tdcstat win=pmtPanel, title="Start TDC"
	else
		tdcstarted = 1
		Button tdcstat win=pmtPanel, title="Stop TDC"
	endif
End
