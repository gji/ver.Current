#pragma rtGlobals=1		// Use modern global access method and strict wave access.

//_____________________________________________________________________________
//
// AWGUploadWaveform() tests the AWG control. It creates a sine wave based on the input
// frequency and duration, uploads the waveform to the AWG, and sets the trigger mode to
// external triggering
//_____________________________________________________________________________
//
Function AWGUploadWaveform()
	SetDataFolder root:AWG
	wave uploadwave		=	root:awg:uploadwave
	NVAR curSegNo = root:awg:curSegNo
	NVAR curSegLen = root:awg:curSegLen
	uploadwave[Dimsize(uploadwave,0)-1-curSegLen] = 0
	AWGclear					// Clear AWG memory and stop output
//	Print  UploadWave
	AWGupload/N=(curSegNo+1) UploadWave	// Upload the waveform to AWG memory
	AWGactivate 2	  		// Set trigger mode to external	
End

//_____________________________________________________________________________
//
//	CalculateSBCWaveform(expt) calculates the sideband cooling pulse durations
//	for each of the mode frequencies
//_____________________________________________________________________________
//
function CalculateSBCWaveform(expt, SBCIdx, awgTTLs)
	STRUCT Experiment &expt
	Variable SBCIdx
	Wave awgTTLs
	
	SetDataFolder root:AWG
	Variable k, j = 0
	Variable durationIdx

	expt.ExOps[SBCIdx].SBCPumpingTime = 5 // Default pumping time in us
	Variable numModes = ItemsInList(expt.ExOps[SBCIdx].SBCFrequencies)
	Variable totalPumpingDuration, numPumpingCycles, maxCycle = 0
	
	WAVE SBCCycles		=	root:AWG:SBCcycles
	WAVE SBCAmplitudes	=	root:AWG:SBCAmplitudes
	WAVE SBCFrequencies	=	root:AWG:SBCFrequencies
	
	Redimension/N=(numModes) SBCCycles,SBCAmplitudes,SBCFrequencies
	
 	SBCCycles = 0
	SBCAmplitudes = 2047
	SBCFrequencies = 0
	
	for (k=0; k< numModes; k+=1)
		SBCCycles[k] = str2num(StringFromList(k, expt.ExOps[SBCIdx].SBCCycles))
		SBCAmplitudes[k] = str2num(StringFromList(k, expt.ExOps[SBCIdx].SBCAmplitudes))
		SBCFrequencies[k] = str2num(StringFromList(k, expt.ExOps[SBCIdx].SBCFrequencies))
		numPumpingCycles += SBCCycles[k]
		maxCycle = max(SBCCycles[k], maxCycle)
	endfor
	totalPumpingDuration = numPumpingCycles * expt.ExOps[SBCIdx].SBCPumpingTime
	WAVE SBCTime	=	root:AWG:SBCTime
	Redimension/N=(numModes,maxCycle) SBCTime
	SBCTime=0
	//Make/O/N=(numModes, maxCycle) SBCTimesTranspose = 0
	for (k=0; k< numModes; k+=1)
		SBCTime[k][0] = str2num(StringFromList(k, expt.ExOps[SBCIdx].SBCTimes))
	endfor
	for (k=0; k< numModes; k+=1)
		for (j=0; j< SBCCycles[k]; j+=1)
			SBCTime[k][j] = SBCTime[k][0]/sqrt(j+1)
		endfor
	endfor
	Variable SBCTotalTime = sum(SBCTime) + totalPumpingDuration
	expt.ExOps[SBCIdx].SBCTotalTime = SBCTotalTime
	
	Redimension/N=(numPumpingCycles*2,2) awgTTLs
	
	WAVE SBCWaveform	=	root:AWG:SBCWaveform
	Redimension/N=(SBCTotalTime*1000) SBCWaveform
	SBCWaveform[]	=	2048
	//SBCTimesTranspose = SBCTimes
	//MatrixTranspose SBCTimesTranspose
	//Reverse/DIM=1 SBCTimes
	
	WAVE TTLNames = root:ExpParams:TTLNames
	WAVE NameWave = root:ExpParams:NameWave
	FindValue/TEXT="Pump" TTLNames
	Variable pump_ttl = NameWave[V_Value]
	FindValue/TEXT="SBCooling" TTLNames
	Variable sb_ttl = NameWave[V_Value]
	
	Variable t, tk, seq_id
	t = 0
	seq_id = 0
	for (k=0; k< numModes; k+=1)
		for (j=SBCCycles[k] - 1; j >=0 ; j-=1)
			if (SBCTime[k][j] != 0)
				tk = t 
				for (t =  tk; t< tk + 1000*round(SBCTime[k][j]); t+=1) 
					SBCWaveform[t]=AWGWaveformPoint_SBCooling(t, SBCAmplitudes[k], SBCFrequencies[k])
				endfor
				awgTTLs[seq_id][0] = sb_ttl
				awgTTLs[seq_id][1] = round(SBCTime[k][j])*49.622
				seq_id = seq_id + 1
				tk = t
				for (t =  tk; t<  tk + 1000*round(expt.ExOps[SBCIdx].SBCPumpingTime); t+=1) 
					SBCWaveform[t]=AWGWaveformPoint(t, SBCIdx, "Pumping", expt)
				endfor
				awgTTLs[seq_id][0] = sb_ttl | pump_ttl
				awgTTLs[seq_id][1] = expt.ExOps[SBCIdx].SBCPumpingTime*49.622
				seq_id = seq_id + 1
			endif
		endfor
	endfor
end
//_____________________________________________________________________________
//
// ConstructAWGWaveform(expt) constructs the waveform, one point per nanosecond, 
// storing it as a global wave. Construction is based on the input Experiment structure expt.
//_____________________________________________________________________________
//

function/WAVE ConstructAWGWaveform(expt, seg_num)
	STRUCT Experiment &expt
	variable seg_num
	
	WAVE awgwave			=root:awg:awgwaveform
	WAVE UploadWave		=root:awg:uploadwave
	
	NVAR curSegNo = root:awg:curSegNo
	NVAR curSegLen = root:awg:curSegLen
		
	ConstructAWGSegment(expt, seg_num)
	
	if(Dimsize(UploadWave,0)<7)
		Redimension/N=(DimSize(AWGwave,0)+7) Uploadwave
		UploadWave[0] 	=	0; // SegmentNum
		UploadWave[1]	=	DimSize(AWGwave, 0); // NumPoints
		UploadWave[2]	=	0; // NumLoops
		UploadWave[3]	=	2047; // BeginPadVal
		UploadWave[4]	=	2047; // EndingPadVal
		UploadWave[5]	=	1; // TrigEn
		UploadWave[6]	=	1; // NextSegNum
		Uploadwave[7,]	=	AWGwave
		curSegNo = 0
	else
		curSegNo += 1
		Redimension/N=(Dimsize(uploadwave,0)+Dimsize(awgwave,0)+7) Uploadwave
		UploadWave[Dimsize(uploadwave,0)-Dimsize(awgwave,0)-7] 	=	curSegNo; // SegmentNum
		UploadWave[Dimsize(uploadwave,0)-Dimsize(awgwave,0)-6]	=	DimSize(awgwave, 0); // NumPoints
		UploadWave[Dimsize(uploadwave,0)-Dimsize(awgwave,0)-5]	=	0; // NumLoops
		UploadWave[Dimsize(uploadwave,0)-Dimsize(awgwave,0)-4]	=	2047; // BeginPadVal
		UploadWave[Dimsize(uploadwave,0)-Dimsize(awgwave,0)-3]	=	2047; // EndingPadVal
		UploadWave[Dimsize(uploadwave,0)-Dimsize(awgwave,0)-2]	=	1; // TrigEn
		UploadWave[Dimsize(uploadwave,0)-Dimsize(awgwave,0)-1]	=	curSegNo+1; // NextSegNum
		variable start = Dimsize(uploadwave,0)-Dimsize(awgwave,0)
		UploadWave[start,]	=	awgwave[p-start]; // NextSegNum
	endif
	
	curSegLen = Dimsize(AWGwave, 0)
	
	return root:awg:awgTTLs
end

//_____________________________________________________________________________
//
// ConstructAWGWSegment(expt) constructs the waveform, one point per nanosecond, 
// storing it as a global wave. Construction is based on the input Experiment structure expt.
//_____________________________________________________________________________
//
function ConstructAWGSegment(expt, ExOpIdx)

	STRUCT Experiment &expt
	variable ExOpIdx
	NVAR shuttleDuration = root:ExpParams:SHUTTLE_DURATION
	Variable shuttleDur = 1000*round(shuttleDuration) // in nano seconds
	SetDataFolder root:AWG
	WAVE SBCWaveform
	WAVE ExOpDurations
	WAVE/T ExOpTypes
	WAVE/T ExOpDevices
	WAVE ExOpPositions
	Variable t, tk, k
	Variable duration = 0
	
	// copy & pasted from PulseGUI - RunExpValues
	Make/D/O/N=(1,2)/I/U awgTTLs // unsigned 32-bit   ; we have 2 columns and rows equal to number of exops
	WAVE TTLNames = root:ExpParams:TTLNames
	WAVE NameWave = root:ExpParams:NameWave
	FindValue/TEXT="SBCooling" TTLNames
	Variable sb_ttl = NameWave[V_Value]
	
	if (cmpstr(expt.ExOps[ExOpIdx].name, "SBCooling") == 0)
		CalculateSBCWaveform(expt, ExOpIdx, awgTTLs)
		duration = 1000*expt.ExOps[ExOpIdx].SBCTotalTime
	else
		duration = 1000*str2num(StringFromList(WhichListItem("Duration", expt.ExOps[ExOpIdx].ControlParameters), expt.ExOps[ExOpIdx].Values))
		awgTTLs[0][0] = sb_ttl
		awgTTLs[0][1] = duration*(50/1000)
	endif
	
	Variable numPoints = (64)*(ceil(round(duration)/64))	// Add padding so that waveform length is multiple of 64
	// Initialize AWG waveform to zero
	
	WAVE AWGwaveform
	Redimension/N=(numPoints,1) AWGwaveform
	AWGwaveform[] = 2048
		
	if(cmpstr(expt.ExOps[ExOpIdx].name, "SBCooling") == 0)
		AWGwaveform[] = SBCWaveform[p];
	else
		for(t=0; t<duration; t+=1)
			AWGwaveform[t] = AWGWaveformPoint(t, ExOpIdx, expt.ExOps[ExOpIdx].name, expt)
		endfor
	endif
	
	if(expt.ExOps[ExOpIdx].Shuttled == 1)
		InsertPoints 0,1,awgTTLs
		awgTTLs[0][0] = TTL_09
		awgTTLs[0][1] = shuttleDur*50
	endif
	
	Redimension/N=(Dimsize(awgTTLs,0)+1,2) awgTTLs
	awgTTLs[Dimsize(awgTTLs,0)][0] = TTL_09
	awgTTLs[Dimsize(awgTTLs,0)][1] = 10
	
end

//_____________________________________________________________________________
//
// AWGWaveformPoint(t, whichExOp, ExOpType) returns the AWG amplitude for a specified time (ns)
// selecting the appropriate wave function based on the input ExOp type (rotation, MS gate, etc)
//_____________________________________________________________________________
//
function AWGWaveformPoint(t, ExOpIdx, ExOpType, expt)

	STRUCT Experiment &expt
	Variable t, ExOpIdx
	String ExOpType
	
	Variable amplitudeIdx
	Variable amplitude
	Variable frequencyIdx
	Variable frequency
	Variable phaseIdx
	Variable phase
	Variable gateDetuningIdx
	Variable gateDetuning
	
	strswitch(ExOpType)
		case "AWGRotation":	// Simple rotation
			amplitudeIdx = WhichListItem("Amplitude", expt.ExOps[ExOpIdx].ControlParameters)
			amplitude = str2num(StringFromList(amplitudeIdx, expt.ExOps[ExOpIdx].Values))
			frequencyIdx = WhichListItem("Frequency", expt.ExOps[ExOpIdx].ControlParameters)
			frequency = str2num(StringFromList(frequencyIdx, expt.ExOps[ExOpIdx].Values))	
			phaseIdx = WhichListItem("Phase", expt.ExOps[ExOpIdx].ControlParameters)
			phase = str2num(StringFromList(phaseIdx, expt.ExOps[ExOpIdx].Values))	
			//printf "%g, %g, %g\r", amplitude, frequency, phase	
			return AWGWaveformPoint_Rotation(t, amplitude, frequency, phase)
		case "MSGate":	// Constant amplitude MSGate
			amplitudeIdx = WhichListItem("Amplitude", expt.ExOps[ExOpIdx].ControlParameters)
			amplitude = str2num(StringFromList(amplitudeIdx, expt.ExOps[ExOpIdx].Values))
			gateDetuningIdx = WhichListItem("GateDetuning", expt.ExOps[ExOpIdx].ControlParameters)
			gateDetuning = str2num(StringFromList(gateDetuningIdx, expt.ExOps[ExOpIdx].Values))	
			phaseIdx = WhichListItem("Phase", expt.ExOps[ExOpIdx].ControlParameters)
			phase = str2num(StringFromList(phaseIdx, expt.ExOps[ExOpIdx].Values))		
			return AWGWaveformPoint_MSGate(t, amplitude, gateDetuning, phase)
		case "Shuttled":	// Sideband cooling
			//amplitudeIdx = WhichListItem("Amplitude", expt.ExOps[ExOpIdx].ControlParameters)
			//amplitude = str2num(StringFromList(amplitudeIdx, expt.ExOps[ExOpIdx].Values))
			//frequencyIdx = WhichListItem("Frequency", expt.ExOps[ExOpIdx].ControlParameters)
			//frequency = str2num(StringFromList(frequencyIdx, expt.ExOps[ExOpIdx].Values))
			//phaseIdx = WhichListItem("Phase", expt.ExOps[ExOpIdx].ControlParameters)
			//phase = str2num(StringFromList(phaseIdx, expt.ExOps[ExOpIdx].Values))		
			return AWGWaveformPoint_Rotation(t, 0, 1,0)
//		case "Delay":
//			amplitudeIdx = WhichListItem("Amplitude", expt.ExOps[ExOpIdx].ControlParameters)
//			amplitude = 2047
//			frequencyIdx = WhichListItem("Frequency", expt.ExOps[ExOpIdx].ControlParameters)
//			frequency = 0	
//			phaseIdx = WhichListItem("Phase", expt.ExOps[ExOpIdx].ControlParameters)
//			phase = 0
//			//printf "%g, %g, %g\r", amplitude, frequency, phase	
//			return AWGWaveformPoint_Rotation(t, amplitude, frequency, phase)
		default:	// Not an AWG ExOp						
			amplitudeIdx = WhichListItem("Amplitude", expt.ExOps[ExOpIdx].ControlParameters)
			amplitude = 2047
			frequencyIdx = WhichListItem("Frequency", expt.ExOps[ExOpIdx].ControlParameters)
			frequency = 0	
			phaseIdx = WhichListItem("Phase", expt.ExOps[ExOpIdx].ControlParameters)
			phase = 0
			//printf "%g, %g, %g\r", amplitude, frequency, phase	
			return AWGWaveformPoint_Rotation(t, amplitude, frequency, phase)
	endswitch
	
end

//_____________________________________________________________________________
//
// AWGWaveformPoint_SBCooling
//_____________________________________________________________________________
//
function AWGWaveformPoint_SBCooling(t, amp, freq)

	Variable t, amp, freq
	Variable period = 1000/freq
	
	// Coerce the amplitude to AWG bounds
	if (amp < 0)
		amp = 0
	else 
		if (amp > 2047)
			amp = 2047
		endif
	endif
	
	return floor(   2047+amp*sin(2 * pi*t / period )  )

end

//_____________________________________________________________________________
//
// AWGWaveformPoint_Rotation(t, amp, freq, phase) returns the amplitude of a simple sine wave
//_____________________________________________________________________________
//
function AWGWaveformPoint_Rotation(t, amp, freq, phase)

	Variable t, amp, freq, phase
	Variable period = 1000/freq
	
	// Coerce the amplitude to AWG bounds
	if (amp < 0)
		amp = 0
	else 
		if (amp > 2047)
			amp = 2047
		endif
	endif
	
	return floor(  2047+ amp*sin(2 * pi*t / (period) + phase*pi/180)  )

end

//_____________________________________________________________________________
//
// AWGWaveformPoint_MSGate(t, carrierFreq, gateDetuning, ampRed, phaseRed, ampBlue, phaseBlue) 
// returns the amplitude of a bichromatic waveform symmetrically-detuned from a carrier frequency
//_____________________________________________________________________________
//
function AWGWaveformPoint_MSGate(t, amplitude, gateDetuning, phase)

	Variable t, amplitude, gateDetuning, phase
	NVAR carrierFreq = root:ExpParams:CARRIER_FREQ
	
	Variable ampRed = amplitude
	Variable ampBlue = amplitude
	Variable phaseRed = phase
	Variable phaseBlue = phase
	Variable periodRed = 1000/(carrierFreq - gateDetuning)
	Variable periodBlue = 1000/(carrierFreq + gateDetuning)
	
	// Coerce the amplitude to AWG bounds	
	if (ampRed < 0)
		ampRed = 0
	else 
		if (ampRed > 1023)
			ampRed = 1023
		endif
	endif
	if (ampBlue < 0)
		ampBlue = 0
	else 
		if (ampBlue > 1023)
			ampBlue = 1023
		endif
	endif
	
	return floor(ampRed*(0.5 + 0.5*cos(2 * pi*t / (periodRed) + phaseRed*pi/180)) 	+ ampBlue*(0.5 + 0.5*cos(2 * pi*t / (periodBlue) + phaseBlue*pi/180)))

end

