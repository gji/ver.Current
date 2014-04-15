#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Macro InitializePMT()
	SetupPMTFiles()
	pmtPanel()
EndMacro

function SetupPMTFiles()
	NewDataFolder /O/S root:PMT
	SetDataFolder root:PMT
	
	Variable/G pmtstarted = 0
	Variable/G pmt_stor_loc = 0
end

Window pmtPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1094,1583,1210,1620) as "PMT Control"
	ModifyPanel cbRGB=(65534,65534,65534)
	SetDrawLayer UserBack
	Button pmtStat,pos={18,9},size={81,18},title="Start PMT", proc=PMTStart
	ToolsGrid snap=1,visible=1
EndMacro

// t is in ms
function/WAVE pmtData(t, reps)
	Variable t
	Variable reps
	
	SetDataFolder root:PMT
	Make/O/D pmt_cmd = {{0, 0x01000000, 0}, {5, t*50, 5}}
	sendSequence(pmt_cmd)
	
	return runSequence(reps, recmask = 0x01000000)
end

function GetPMTData(s)
	STRUCT WMBackgroundStruct &s
	
	SetDataFolder root:PMT
	Wave counts
	Wave counts_hist
	NVAR pmt_stor_loc
	
	Wave out = pmtData(5000, 20)
	//counts[] = out[p]	
	
	Histogram/B={0,1,100} out,counts_hist
	
	pmt_stor_loc = pmt_stor_loc + 1
	if(pmt_stor_loc >= 100)
		pmt_stor_loc = 0
	endif
	
	return 0
end

Function PMTStart(ctrlName) : ButtonControl
	String ctrlName
	SetDataFolder root:PMT
	
	NVAR pmtstarted
	if(pmtstarted == 1)
		pmtstarted = 0
		CtrlNamedBackground PMT_task, stop
		Button pmtstat win=pmtPanel, title="Start PMT"
	else
		pmtstarted = 1
		Make/N=100/O counts
		counts = 0
		Make/N=100/O counts_hist
		Display/K=1 counts_hist
		CtrlNamedBackground PMT_task, period=60, proc=GetPMTData
		CtrlNamedBackground PMT_task, start
		Button pmtstat win=pmtPanel, title="Stop PMT"
	endif
End