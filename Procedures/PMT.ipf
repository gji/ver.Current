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
	NewPanel /W=(1094,1583,1210,1644) as "PMT Control"
	ModifyPanel cbRGB=(65534,65534,65534)
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

	
	return runSequence(reps, recmask = 0x01000000)
end

function GetPMTData(s)
	STRUCT WMBackgroundStruct &s
	
	SetDataFolder root:PMT
	Wave counts_hist
	Wave avg_counts
	NVAR pmt_stor_loc
	
	if(avg_counts[99]>0)
		DeletePoints 0,1, avg_counts
		Redimension/N=100 avg_counts
	endif
	
	
	Wave out = pmtData(50000, 20) // 5000 is integration time in us, 20 is reps
	//counts[] = out[p]	
	
	
	avg_counts[99]	= Mean(out)
	Histogram/B={0,1,100} out,counts_hist
	
	return 0
end

Function PMTStart(ctrlName) : ButtonControl
	String ctrlName
	SetDataFolder root:PMT
	
	NVAR pmtstarted
	if(pmtstarted == 1)
		pmtstarted = 0
		CtrlNamedBackground PMT_task, stop
		KillWindow PMTCNT
		KillWindow PMTAVGCNT
		Button pmtstat win=pmtPanel, title="Start PMT"
	else
		pmtstarted = 1
		Make/N=100/O counts
		counts = 0
		Make/N=100/O counts_hist
		Display/K=1/N=PMTCNT counts_hist
		ModifyGraph mode=6
		Make/N=100/O avg_counts
		Display/K=1/N=PMTAVGCNT avg_counts
		ModifyGraph mode=3
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
