#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Macro InitializeCamera()
	Initialize()
	CamControl()
	Menu "GraphMarquee", dynamic
		SetROIText(1), MarqueeSetROI()
		SetROIText(2),MarqueeExpandROI()
	End
EndMacro

Window CamControl() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(1458,133,1828,467) as "Camera Control"
	ModifyPanel cbRGB=(65534,65534,65534)
	Button startCap,pos={28,55},size={116,26},disable=2,proc=EventStartCapture,title="Start Capture"
	Button stopCap,pos={27,90},size={117,27},disable=2,proc=EventStopCapture,title="Stop Capture"
	SetVariable setExpLarge,pos={164,27},size={178,18},bodyWidth=100,proc=VarCamUpdate,title="Exposure (ms)"
	SetVariable setExpLarge,limits={0,999999,1},value= root:Camera:EXPOSURE_LARGE
	SetVariable exposurelow,pos={168,45},size={174,18},bodyWidth=100,proc=VarCamUpdate,title="Exposure (ns)"
	SetVariable exposurelow,limits={3,999980,20},value= root:Camera:EXPOSURE_SMALL
	SetVariable delayhigh,pos={182,81},size={160,18},bodyWidth=100,proc=VarCamUpdate,title="Delay (ms)"
	SetVariable delayhigh,limits={0,999999,1},value= root:Camera:DELAY_LARGE
	SetVariable delaylow,pos={186,99},size={156,18},bodyWidth=100,proc=VarCamUpdate,title="Delay (ns)"
	SetVariable delaylow,limits={0,999999,20},value= root:Camera:DELAY_SMALL
	Button openCam,pos={27,18},size={117,27},proc=EventOpenCamera,title="Open Camera"
	SetVariable roiymax,pos={77,137},size={49,18},bodyWidth=30,proc=VarCamUpdate,title="Y+"
	SetVariable roiymax,limits={1,32,1},value= root:Camera:ROI[1][1]
	SetVariable roixmin,pos={53,162},size={46,18},bodyWidth=30,proc=VarCamUpdate,title="X-"
	SetVariable roixmin,limits={1,40,1},value= root:Camera:ROI[0],noedit= 1
	SetVariable roixmax,pos={104,162},size={49,18},bodyWidth=30,proc=VarCamUpdate,title="X+"
	SetVariable roixmax,limits={1,40,1},value= root:Camera:ROI[1]
	SetVariable roiymin,pos={79,189},size={46,18},bodyWidth=30,proc=VarCamUpdate,title="Y-"
	SetVariable roiymin,limits={1,32,1},value= root:Camera:ROI[0][1]
	SetVariable xbins,pos={173,146},size={61,18},bodyWidth=30,proc=EventXBins,title="X Bin"
	SetVariable xbins,limits={0,999999,1},value= root:Camera:BINS[0]
	SetVariable ybins,pos={173,180},size={61,18},bodyWidth=30,proc=EventYBins,title="Y Bin"
	SetVariable ybins,limits={0,999999,1},value= root:Camera:BINS[1]
	SetVariable gainCont,pos={266,135},size={58,18},bodyWidth=30,proc=VarCamUpdate,title="Gain"
	SetVariable gainCont,limits={0,999999,1},value= root:Camera:GAIN
	SetVariable decayCont,pos={258,153},size={66,18},bodyWidth=30,proc=VarCamUpdate,title="Decay"
	SetVariable decayCont,limits={0,999999,1},value= root:Camera:DECAY
	SetVariable trigCont,pos={252,171},size={72,18},bodyWidth=30,proc=VarCamUpdate,title="Trigger"
	SetVariable trigCont,limits={0,999999,1},value= root:Camera:TRIGGER
	SetVariable loopCont,pos={258,189},size={66,18},bodyWidth=30,proc=VarCamUpdate,title="Loops"
	SetVariable loopCont,limits={0,999999,1},value= root:Camera:LOOPS
	SetVariable FPSDisplay,pos={306,0},size={63,18},bodyWidth=40,title="FPS"
	SetVariable FPSDisplay,limits={-inf,inf,0},value= root:Camera:FPS[0],noedit= 1
	Button rangeCont,pos={126,252},size={117,27},proc=EventRangeSet,title="Hold Range"
	SetVariable rangeMax,pos={196,225},size={74,18},bodyWidth=48,proc=EventNewRange,title="Max"
	SetVariable rangeMax,limits={1,4096,1},value= root:Camera:RANGE[2]
	SetVariable rangeMin,pos={96,225},size={75,18},bodyWidth=50,proc=EventNewRange,title="Min"
	SetVariable rangeMin,limits={1,4096,1},value= root:Camera:RANGE[1]
	Button setBGSub,pos={35,288},size={100,30},proc=BGSet,title="Set BG"
	Button remBGSub,pos={153,288},size={100,30},proc=BGSet,title="Remove BG"
	SetVariable bglvl,pos={263,294},size={79,18},bodyWidth=48,title="Level"
	SetVariable bglvl,limits={1,4096,1},value= root:Camera:BG_LVL
	ToolsGrid snap=1,visible=1
EndMacro

Function Initialize()
	NewDataFolder /O/S root:Camera
	SetDataFolder root:Camera
	
	Variable/G MODE = 5
	Make/O/N=(2,2) ROI = {{1,40},{1,32}}
	Make/O/N=2 BINS = {1,1}
	Variable/G DECAY = 10
	Variable/G GAIN = 0
	Variable/G TRIGGER = 0
	Variable/G LOOPS = 1
	Variable/G DELAY_LARGE = 0
	Variable/G DELAY_SMALL = 0
	Variable/G EXPOSURE_LARGE = 0
	Variable/G EXPOSURE_SMALL = 0
	Variable/G CAMERA_INIT = 0
	
	Variable/G COC_RUNNING = 0
	
	Variable/G BG_LVL = 0
	
	Make/O/N=1 FPS
	Make/O/N=2 RANGE = {1,0,4096} // 0 for hold, 1 for auto, max camera range
End

// this thread must be threadsafe!! it runs concurrently with the GUI.

ThreadSafe Function GetCamData(temp, temp_Hist, FPS,Lineplot,LineplotStDev, LineFFT, RANGE)
	Wave temp, temp_Hist, FPS, Lineplot, LineplotStDev, LineFFT, RANGE
	
	Make/N=51/O FFT_local
	Make/N=4096/O temp_Hist_thread
	
	Variable bglvl = 0
	Variable bgsub = 0
	
	Duplicate/O temp, buf

	do
		Variable timeEl = ticks
		PCOCamExecCOC buf
		
		DFREF dfr = ThreadGroupGetDFR(0,0)
		if (DataFolderRefStatus(dfr) != 0)
			SetDataFolder dfr
			NVAR BG_SUB_OUT
		 	NVAR BG_LVL_OUT
			Duplicate/O buf, bg
			bgsub = BG_SUB_OUT
			bglvl = BG_LVL_OUT
			SetDataFolder root
			print bgsub
		endif
		
		if(bgsub == 1)
			temp = buf - bg + bglvl
		else
			temp = buf
		endif

		// if auto ranging, update fields. this way we can grab the current range when the user wants to hold range

		if(RANGE[0] == 1)
			RANGE[1] = WaveMin(temp)
			RANGE[2] = WaveMax(temp)
		endif
		
		// calculate local histogram, copy to displayed histogram.
		Histogram/B={0,1,4096} temp,temp_Hist_thread
		temp_Hist = temp_Hist_thread[p]
		
		variable totalPhotons = 0
		variable totalPhotonsStDev = 0
		variable i
		for( i = 0;i<4096;i+= 1)	// count the total number of photons from the histogram. bit faster.
			totalPhotons += temp_Hist_thread[i] * i
			totalPhotonsStDev=totalPhotons								
		endfor	
		totalPhotons/=(1024*1280)
		totalPhotonsStDev/=(1024*1280)
		Lineplot = Lineplot[p+1]
		Lineplot[99] = totalPhotons
		LineplotStDev=	LineplotStDev[p+1]
		LineplotStDev[99]	= Variance(Lineplot)						
 
 		FFT/OUT=3/DEST=FFT_local Lineplot
 		LineFFT = FFT_local[p]
 		
		FPS[0] = round((FPS[0] + 10 * 60/(ticks-timeEl))/11) // weighted average
	while (1)
End

Function StartExposureThread()
	SetDataFolder root:Camera
	NVAR MODE
	NVAR DECAY
	NVAR GAIN
	NVAR TRIGGER
	NVAR LOOPS
	NVAR DELAY_LARGE
	NVAR DELAY_SMALL
	NVAR EXPOSURE_LARGE
	NVAR EXPOSURE_SMALL
	NVAR COC_RUNNING = root:Camera:COC_RUNNING
	WAVE ROI
	WAVE BINS
	WAVE FPS
	WAVE RANGE
	
	COC_RUNNING=1
	
	String exposureString = num2str(DECAY) +","+ num2str(GAIN) +","+ num2str(TRIGGER) +","+ num2str(LOOPS)
	exposureString += ","+ num2str(DELAY_LARGE) +","+ num2str(DELAY_SMALL) +","+ num2str(EXPOSURE_LARGE) +","+ num2str(EXPOSURE_SMALL)
	exposureString += ",-1,-1"
	
	PCOCamSendCOC/M=(MODE)/T=0/B={BINS[0],BINS[1]}/R={ROI[0][0],ROI[1][0],ROI[0][1],ROI[1][1]} exposureString
	Variable xDim = 32 * (ROI[1][0]-ROI[0][0]+1) / BINS[0]
	Variable yDim = 32 * (ROI[1][1]-ROI[0][1]+1) / BINS[1]
	Make/O/N=(xDim,yDim)/W temp
	DoWindow/K camView
	NewImage/N=camView/K=1 temp
	SetAxis/A/R left
	ModifyImage temp log=1
	ModifyImage temp ctab= {*,*,VioletOrangeYellow,0}
	
	Make/N=4096/O temp_Hist
	DoWindow/K camHist
	Display/K=1/W=(1000,150,1400,300)/N=camHist temp_Hist
	ModifyGraph mode=6 // sets the graph to cityscape. better way to represent histogram
	ModifyGraph log(left)=1
	HoldUpdate(0)
	
	// this is the displayed lineplot. like with the histogram, we need two separate ones, because of threading.
	
	Make/O/N=100 Lineplot
	DoWindow/K totalPhotons
	Make/O/N=2 coords
	Display/K=1/W=(1000,300,1400,450)/N=totalPhotons Lineplot //[lineplotLowerPointer,lineplotPointer]
	Make/O/N=100 LineplotStDev
	DoWindow/K totalPhotonsStDev
	Display/K=1/W=(1000,450,1400,600)/N=totalPhotonsStDev LineplotStDev //[lineplotLowerPointer,lineplotPointer]
	Make/O/N=51 LineFFT
	DoWindow/K totalPhotonFFT
	Display/K=1/W=(1000,600,1400,750)/N=totalPhotonFFT LineFFT[10,51] //[lineplotLowerPointer,lineplotPointer]
	ModifyGraph mode=6
	
	Variable/G mt = ThreadGroupCreate(1)
	ThreadStart mt, 0, GetCamData(temp, temp_Hist, FPS,Lineplot,LineplotStDev, LineFFT, RANGE) // Start thread
End


// all events. the first ones are button controls to just start/stop the camera.

Function EventStartCapture(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	NVAR captureRunning 
	
	switch( ba.eventCode )
		case 2: // mouse up
			Button startCap disable=2
			Button stopCap disable=0
			captureRunning = 1
			StartExposureThread()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function EventStopCapture(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SetDataFolder root:Camera
	NVAR mt = root:Camera:mt
	NVAR COC_RUNNING

	switch( ba.eventCode )
		case 2: // mouse up
			Button startCap disable=0
			Button stopCap disable=2
			Variable foo = ThreadGroupRelease(mt)
			COC_RUNNING=0
			PCOCamStop
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function EventOpenCamera(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	NVAR mt = root:Camera:mt
	NVAR CAMERA_INIT

	switch( ba.eventCode )
		case 2: // mouse up
			if(CAMERA_INIT == 0)
				PCOCamInit
				Button openCam title="Close Camera"
				Button startCap disable=0
				Button stopCap disable=2
				CAMERA_INIT = 1
			else
				// cleaning up threads and COC just in case
				Variable foo = ThreadGroupRelease(mt)
				PCOCamStop
				// deallocate camera
				PCOCamFree
				Button openCam title="Open Camera"
				Button startCap disable=2
				Button stopCap disable=2
				CAMERA_INIT = 0
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// BG Subtraction stuff

Function BGSet(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SetDataFolder root:Camera
	
	NVAR BG_LVL
	NVAR mt
	WAVE temp
	
	switch( ba.eventCode )
		case 2: // mouse up
			NewDataFolder/S/O forThread
			Variable/G BG_SUB_OUT, BG_LVL_OUT
			if(ba.ctrlName[0]==char2num("s"))
				BG_SUB_OUT = 1
				BG_LVL_OUT = BG_LVL
			else
				BG_SUB_OUT = 0
			endif
			ThreadGroupPutDF mt,:
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// flip flopping the ranging style, auto or held. note that when holding, we hold to the lastest auto exposure values

Function EventRangeSet(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SetDataFolder root:Camera
	Wave temp, RANGE

	switch( ba.eventCode )
		case 2: // mouse up
			HoldUpdate(1)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function HoldUpdate(switching)
Variable switching
Wave temp,RANGE

if((RANGE[0] == 1 && switching ==1 )|| (RANGE[0] ==0 && switching ==0))
				Button rangeCont title="Auto Range"
				ModifyImage/W=camView temp ctab= {RANGE[1],RANGE[2],VioletOrangeYellow,0}
				RANGE[0] = 0
			else
				Button rangeCont title="Hold Range"
				ModifyImage/W=camView temp ctab= {*,*,VioletOrangeYellow,0}
				RANGE[0] = 1
			endif
End

// these methods round the bins to an an allowed power of two. since the XOP uses memcpy, and does this
// rounding internally already, the memcpy'd data can be larger or smaller than the igor wave. in the 
// former case, this causes a buffer overflow which crashes igor quite badly.

Function EventXBins(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	SetDataFolder root:Camera
	WAVE BINS

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			Variable newval = round(log(dval)/log(2))
			if(newval < 0)
				newval = 0
			elseif(newval > 3)
				newval = 3
			endif
			BINS[0] = 2^newval
			CamUpdate()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function EventYBins(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	SetDataFolder root:Camera
	WAVE BINS

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			Variable newval = round(log(dval)/log(2))
			if(newval < 0)
				newval = 0
			elseif(newval > 10)
				newval = 10
			endif
			BINS[1] = 2^newval
			CamUpdate()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Updates the camera if you change a variable
Function VarCamUpdate(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	
	
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update	
			CamUpdate()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// this event updates the displayed range, only if the exposure is held (not auto)

Function EventNewRange(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	SetDataFolder root:Camera
	Wave temp, RANGE

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			if(RANGE[0] == 0)
				Button rangeCont title="Auto Range"
				ModifyImage/W=camView temp ctab= {RANGE[1],RANGE[2],VioletOrangeYellow,0}
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function MarqueeSetROI()
	Wave ROI
	String format
	GetMarquee/K/W=camView left, top

	Variable left, right, top, bottom
	left = floor(V_left /32) +ROI[0]
	right = ceil( V_right/32) + ROI[0]
	top=ceil( V_top /32) +ROI[0][1]
	bottom=floor( V_bottom/32) + ROI[0][1]
	//check boundries
	If (left>40) 
		left=40
	elseif (left<1)
		left = 1 
	endif
	If (right>40) 
		right=40
	elseif (right<1)
		right = 1 
	endif
	If (top>32) 
		top=32
	elseif (top<1)
		top = 1 
	endif
	If (bottom>32) 
		bottom=42
	elseif (bottom<1)
		bottom = 1 
	endif
	format = "flag: %g; left: %g; top: %g; right: %g; bottom: %g\r"
	printf format, V_flag, left,top,right,bottom
	ROI[0][0] = left
	ROI[1][0] = right
	ROI[0][1] = top
	//print bottom
	print ROI[0][1] - ROI[1][1]
	ROI[1][1] = bottom
	CamUpdate()
End

//Function ZoomOutROI()
//print "hello"
//END

Function MarqueeExpandROI()
	Wave ROI
	ROI[0][0] = 1
	ROI[1][0] = 40
	ROI[0][1] = 1
	ROI[1][1] = 32
	CamUpdate()
END

Function/S SetROIText(itemNumber)
	Variable itemNumber
	GetMarquee/Z
	if (V_flag ==1)
		strswitch(S_marqueeWin)
			case"camView":
				switch(itemNumber)
					case 1:
						return "Set Region of Interest"
						break
					case 2:
						return "Zoom out Region of Interest"
						break
					default:
						return ""
						break
				endswitch
				break
			default:
				return ""
				break
		endswitch
	else
		return ""
	endif
End

Function CamUpdate() //just quickly stops and restarts the camera with new settings
	SetDataFolder root:Camera

	NVAR COC_RUNNING = root:Camera:COC_RUNNING

	if (COC_RUNNING ==1)
		SetDataFolder root:Camera
		NVAR mt = root:Camera:mt
		Variable foo = ThreadGroupRelease(mt)
		PCOCamStop
		
		StartExposureThread()
		
	endif
End

