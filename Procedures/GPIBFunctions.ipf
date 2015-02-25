#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// GPIB Commands for Oven
// Turns Oven On/Off
Function Oven_Output(x)
	Variable x
	NVAR OvenRef = root:GPIBparams:OvenRef
	GPIB2 device = OvenRef
	if (x)
		GPIBWrite2 "OUTP ON"
	elseif(x==0)
		GPIBWrite2 "OUTP OFF"
	endif
	GPIBWrite2 "OUTP?"
	String onOff 
	GPIBRead2 onOff
	if (str2num(onOff)==1)
		print "Oven On"
	elseif(str2num(onOff)==0)
		print "Oven Off"
	endif
End
// Sets Oven Voltage 
Function Oven_Voltage(x)
	Variable x
	NVAR OvenRef = root:GPIBparams:OvenRef
	GPIB2 device = OvenRef
	GPIBWrite2 "VOLT "+num2str(x)
	GPIBWrite2 "MEAS:VOLT?"
	String voltage
	GPIBRead2 voltage
	print "Oven Voltage: "+voltage
End
// Sets Oven Current
Function Oven_Current(x)
	Variable x
	NVAR OvenRef = root:GPIBparams:OvenRef
	GPIB2 device = OvenRef
	GPIBWrite2 "CURR "+num2str(x)
	GPIBWrite2 "MEAS:CURR?"
	String current
	GPIBRead2 current
	print "Oven Current: "+current
End

// GPIB Commands for TrapRF
// Sets Trap RF Amplitutde
Function Trap_RF_Amp(x)
	Variable x
	NVAR TrapRFRef = root:GPIBparams:TrapRFRef
	string amplitude
	GPIB2 device = TrapRFRef
	GPIBWrite2 "FUNC 0"
	if (x<-12.000)
		GPIBWrite2 "AMPL "+num2str(x)+"DB"
		print num2str(x)
	else
		doAlert 0, "TrapRF Amplitude is too high!"
	endif
	GPIBWrite2 "AMPL?DB"
	GPIBRead2 amplitude
	GPIBWrite2 "AMPL?DB"
	GPIBRead2 amplitude	
	print "Trap Amplitude: "+amplitude	
End
// Sets Trap RF Frequency
Function Trap_RF_Freq(x)
	Variable x
	x*=10^6
	NVAR TrapRFRef = root:GPIBparams:TrapRFRef
	String frequency
	Variable num_frequency
	GPIB2 device = TrapRFRef
	GPIBWrite2 "FUNC 0"
	GPIBWrite2 "FREQ "+num2str(x)
	GPIBWrite2 "FREQ ?"
	GPIBRead2 frequency	
	GPIBWrite2 "FREQ ?"
	GPIBRead2 frequency
	num_frequency =str2num(frequency)/10^6
	print "Trap Frequency: "+num2str(num_frequency)	
End
// Sets Trap RF Offset
Function Trap_RF_Offset(x)
	Variable x
	NVAR TrapRFRef = root:GPIBparams:TrapRFRef
	GPIB2 device = TrapRFRef
	GPIBWrite2 "FUNC 0"
	GPIBWrite2 "OFFS "+num2str(x)
	GPIBWrite2 "OFFS?"
	String offset
	GPIBRead2 offset
	print "Trap DC Offset: "+offset
End

// GPIB Commands for Lab Clock
// Power On & Off
Function Clock_Frequency(x)
	Variable x
	NVAR LabClock = root:GPIBparams:LabClock
	GPIB2 device = LabClock
	GPIBWrite2 "F" + num2istr(x*1000000000) + "\nA1\n"
End

// Creates Panel Containing GPIB Commands for Oven and TrapRF
Window GPIBCtrl() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(1350,750,1909,907) as "GPIB Commands"
	ModifyPanel cbRGB=(50432,39424,59136)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (65280,43520,0),fsize= 14
	SetDrawEnv save
	Button OvenOnOffCtrl,pos={51,90},size={95,23},bodyWidth=75,proc=OvenUpdate,title="Oven On"
	Button TrapRFCtrl,pos={233,91},size={111,23},bodyWidth=75,proc=TrapRFUpdate,title="Trap RF Update"
	Button AutoLoad_Ctrl,pos={235,117},size={110,26},bodyWidth=75,proc=AutoLoadIon,title="Autoload"
	Button AutoLoadStop_Ctr,pos={45,116},size={110,24},bodyWidth=75,proc=AutoLoadStop,title="Autoload Stop"
	Button LabClockCtrl,pos={437,92},size={95,23},bodyWidth=75,proc=ClockUpdate,title="Clock Update"
	SetVariable OvenVoltageCtrl,pos={3,41},size={151,18},bodyWidth=75,title="Oven Voltage"
	SetVariable OvenVoltageCtrl,limits={0,2,0.01},value= root:GPIBparams:OvenVoltage
	SetVariable OvenCurrentCtrl,pos={3,18},size={151,18},bodyWidth=75,title="Oven Current"
	SetVariable OvenCurrentCtrl,limits={0,2.8,0.01},value= root:GPIBparams:OvenCurrent
	SetVariable TrapRFAmplitudeCtrl,pos={178,15},size={181,18},bodyWidth=75,title="Trap RF Amplitude"
	SetVariable TrapRFAmplitudeCtrl,limits={-20,-12,0.01},value= root:GPIBparams:TrapRFamplitude
	SetVariable TrapRFFrequencyCtrl,pos={178,39},size={183,18},bodyWidth=75,title="Trap RF Frequency"
	SetVariable TrapRFFrequencyCtrl,limits={0.1,30,0.0001},value= root:GPIBparams:TrapRFfrequency
	SetVariable TrapRFOffsetCtrl,pos={203,62},size={158,18},bodyWidth=75,title="Trap RF Offset"
	SetVariable TrapRFOffsetCtrl,limits={-2,2,0.01},value= root:GPIBparams:TrapRFoffset
	SetVariable LabClockFrequencyCtrl,pos={374,20},size={170,18},bodyWidth=75,title="Clock Frequency"
	SetVariable LabClockFrequencyCtrl,limits={0,1.1,0.01},value= root:GPIBparams:ClockFrequency, format="%0.6f"
EndMacro

// Updates GPIB Commands Panel
// Updates Clock Frequency
Function ClockUpdate(ba) :ButtonControl
	STRUCT WMButtonAction &ba
	String fldrSav0= GetDataFolder(1)	
	setDatafolder root:GPIBparams
	NVAR ClockFrequency
	switch( ba.eventCode )	
		case 2: // mouse up
			Clock_Frequency(ClockFrequency)
			break
		case -1:
			break
	endswitch
	setDatafolder fldrSav0	
end

// Updates Oven Settings
Function OvenUpdate(ba) :ButtonControl
	STRUCT WMButtonAction &ba
	String fldrSav0= GetDataFolder(1)	
	setDatafolder root:GPIBparams
	NVAR OvenOutputFlag
	NVAR OvenCurrent
	NVAR OvenVoltage
	switch( ba.eventCode )	
		case 2: // mouse up
			if(OvenOutputFlag)
				Oven_Current(OvenCurrent)
				Oven_Voltage(OvenVoltage)
				Oven_Output(1)
				Button OvenOnOffCtrl, title="Oven Off"
				OvenOutputFlag=0
			elseif (OvenOutputFlag==0)
				Oven_Current(OvenCurrent)
				Oven_Voltage(OvenVoltage)				
				Oven_Output(0)
				Button OvenOnOffCtrl, Title="Oven On"
				OvenOutputFlag=1
			endif
			break
		case -1:
			break
	endswitch
	setDatafolder fldrSav0
end

Function AutoLoadBackground(s) // This is the function that will be called periodically
	STRUCT WMBackgroundStruct &s
	String fldrSav0= GetDataFolder(1)	
	NVAR OvenCurrent		=	root:GPIBparams:OvenCurrent
	NVAR OvenVoltage		=	root:GPIBparams:OvenVoltage
	NVAR OvenOutputFlag	=	root:GPIBparams:OvenOutputFlag	
	setDatafolder root:Camera
	wave ionhere
	if(Sum(IonHere)==0)
		setDatafolder fldrSav0
		Print "not Loaded"
		return 0
	elseif(IonHere)
		Oven_Current(OvenCurrent)
		Oven_Voltage(OvenVoltage)	
		Oven_Output(0)
		Button OvenOnOffCtrl, title="Oven On"
		TTL_wrapper("TTL16_Switch",0)
		OvenOutputFlag=0
		IonHere=0
		setDatafolder fldrSav0
		Print "Ion Loaded"
		return 1
	else
		Oven_Current(OvenCurrent)
		Oven_Voltage(OvenVoltage)	
		Oven_Output(0)
		Button OvenOnOffCtrl, title="Oven On"
		TTL_wrapper("TTL16_Switch",0)
		OvenOutputFlag=1
		IonHere=0
		setDatafolder fldrSav0
		Print "Ion Load error"
		return 2
	endif
	//setDatafolder fldrSav0
End

Function AutoLoad()
	WAVE IonHere			=	root:Camera:IonHere
	NVAR OvenCurrent		=	root:GPIBparams:OvenCurrent
	NVAR OvenVoltage		=	root:GPIBparams:OvenVoltage
	NVAR OvenOutputFlag	=	root:GPIBparams:OvenOutputFlag
	Variable flag=0
//	KeyToAbort(1)
	if(Sum(IonHere)==0)
		Oven_Current(OvenCurrent)
		Oven_Voltage(OvenVoltage)	
		Oven_Output(1)
		Button OvenOnOffCtrl, title="Oven Off"
		TTL_wrapper("TTL16_Switch",0)
		OvenOutputFlag=0
	else
		Oven_Current(OvenCurrent)
		Oven_Voltage(OvenVoltage)	
		Oven_Output(0)
		Button OvenOnOffCtrl, title="Oven On"
		TTL_wrapper("TTL16_Switch",1)
		OvenOutputFlag=1
		IonHere=0
	endif
	CtrlNamedBackground Auto_Load, period=120,proc=AutoLoadBackground
	CtrlNamedBackground Auto_Load, start	
end

Function AutoLoadIon(ba) :ButtonControl
	STRUCT WMButtonAction &ba
	String fldrSav0= GetDataFolder(1)	
	switch( ba.eventCode )	
		case 2: // mouse up
				AutoLoad()
			break
		case -1:
			break
	endswitch
	setDatafolder fldrSav0
end

Function AutoLoadStop(ba) :ButtonControl
	STRUCT WMButtonAction &ba
	String fldrSav0= GetDataFolder(1)	
	switch( ba.eventCode )	
		case 2: // mouse up
				CtrlNamedBackground Auto_Load, stop
			break
		case -1:
			break
	endswitch
	setDatafolder fldrSav0
End

// Updates Trap RF Settings
Function TrapRFUpdate(ba) :ButtonControl
	STRUCT WMButtonAction &ba
	String fldrSav0= GetDataFolder(1)	
	setDatafolder root:GPIBparams
	NVAR TrapRFamplitude
	NVAR TrapRFfrequency
	NVAR TrapRFoffset
	switch( ba.eventCode )	
		case 2: // mouse up
			Trap_RF_Offset(TrapRFoffset)
			Trap_RF_Freq(TrapRFfrequency)
			Trap_RF_Amp(TrapRFamplitude)
			break
		case -1:
			break
	endswitch
	setDatafolder fldrSav0	
end
