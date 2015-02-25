#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//function TDC_Integration(HistTDC, Samples)
//	WAVE HistTDC
//	Variable Samples 
//	tdcstartintegration /B=1/C=180/S=(Samples)
//	do
//		sleep/s 1
//		tdcgetsamples
//	while(V_TDC!=Samples)
//	
//	tdcgethistogram HistTDC
//end
//
//function TDC_init()
//	NewDataFolder/O/S root:CompTDC
//	SetDataFolder root:CompTDC
//	Make/o HistTDC
//	
//	
//end
//
//Window CompTDCCtrl() : Panel
//	PauseUpdate; Silent 1		// building window...
//	NewPanel /K=1 /W=(1350,750,1909,907) as "TDC Scan"
//	ModifyPanel cbRGB=(50432,39424,59136)
//	Button OvenOnOffCtrl,pos={51,90},size={95,23},bodyWidth=75,proc=OvenUpdate,title="Oven On"
//	Button TrapRFCtrl,pos={233,91},size={111,23},bodyWidth=75,proc=TrapRFUpdate,title="Trap RF Update"
//	Button AutoLoad_Ctrl,pos={235,117},size={110,26},bodyWidth=75,proc=AutoLoadIon,title="Autoload"
//	Button AutoLoadStop_Ctr,pos={45,116},size={110,24},bodyWidth=75,proc=AutoLoadStop,title="Autoload Stop"
//	Button LabClockCtrl,pos={437,92},size={95,23},bodyWidth=75,proc=ClockUpdate,title="Clock Update"
//EndMacro
