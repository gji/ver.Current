#pragma rtGlobals=1		// Use modern global access method and strict wave access.

//_____________________________________________________________________________
//
// AWGUploadWaveform() tests the AWG control. It creates a sine wave based on the input
// frequency and duration, uploads the waveform to the AWG, and sets the trigger mode to
// external triggering
//_____________________________________________________________________________
//
Function AWGUploadWaveform()
	
	AWGopen					// Open the AWG card
	AWGclear					// Clear AWG memory and stop output
	AWGupload AWGwaveform	// Upload the waveform to AWG memory
	AWGactivate 2				// Set trigger mode to external
	AWGclose					// Close the AWG card
	
End

//_____________________________________________________________________________
//
//	CalculateSBCWaveform(expt) calculates the sideband cooling pulse durations
//	for each of the mode frequencies
//_____________________________________________________________________________
//
function CalculateSBCWaveform(expt)
	STRUCT Experiment &expt
	SetDataFolder root:AWG
	Variable k, j, ExOpIdx = 0
	Variable SBCIdx = 0
	Variable durationIdx
	Variable pumpTime = 5	// Default pumping time
	for (ExOpIdx = 0; ExOpIdx < expt.numExOps; ExOpIdx +=1)
		if (cmpstr(expt.ExOps[ExOpIdx].name, "Pump") == 0)
			durationIdx = WhichListItem("Duration", expt.ExOps[ExOpIdx].ControlParameters)
			pumpTime = str2num(StringFromList(durationIdx, expt.ExOps[ExOpIdx].Values))
			break
		endif
	endfor
	for (ExOpIdx = 0; ExOpIdx < expt.numExOps; ExOpIdx +=1)
		if (cmpstr(expt.ExOps[ExOpIdx].name, "SBCooling") == 0)
			SBCIdx = ExOpIdx
			break
		endif
	endfor
	expt.ExOps[SBCIdx].SBCPumpingTime = pumpTime
	Variable numModes = ItemsInList(expt.ExOps[SBCIdx].SBCFrequencies)
	Variable totalPumpingDuration, numPumpingCycles, maxCycle = 0
	Make/O/N=(numModes) SBCCycles = 0
	Make/O/N=(numModes) SBCAmplitudes = 0
	Make/O/N=(numModes) SBCFrequencies = 0
	for (k=0; k< numModes; k+=1)
		SBCCycles[k] = str2num(StringFromList(k, expt.ExOps[SBCIdx].SBCCycles))
		SBCAmplitudes[k] = str2num(StringFromList(k, expt.ExOps[SBCIdx].SBCAmplitudes))
		SBCFrequencies[k] = str2num(StringFromList(k, expt.ExOps[SBCIdx].SBCFrequencies))
		numPumpingCycles += SBCCycles[k]
		maxCycle = max(SBCCycles[k], maxCycle)
	endfor
	totalPumpingDuration = numPumpingCycles * expt.ExOps[SBCIdx].SBCPumpingTime
	Make/O/N=(numModes, maxCycle) SBCTimes = 0
	//Make/O/N=(numModes, maxCycle) SBCTimesTranspose = 0
	for (k=0; k< numModes; k+=1)
		SBCTimes[k][0] = str2num(StringFromList(k, expt.ExOps[SBCIdx].SBCTimes))
	endfor
	for (k=0; k< numModes; k+=1)
		for (j=0; j< SBCCycles[k]; j+=1)
			SBCTimes[k][j] = SBCTimes[k][0]/sqrt(j+1)
		endfor
	endfor
	Variable SBCTotalTime = sum(SBCTimes) + totalPumpingDuration
	expt.ExOps[SBCIdx].SBCTotalTime = SBCTotalTime
	
	Make/O/N=(1000*SBCTotalTime) SBCWaveform
	//SBCTimesTranspose = SBCTimes
	//MatrixTranspose SBCTimesTranspose
	//Reverse/DIM=1 SBCTimes
	Variable t, tk
	t = 0
	for (k=0; k< numModes; k+=1)
		for (j=SBCCycles[k] - 1; j >=0 ; j-=1)
			if (SBCTimes[k][j] != 0)
				tk = t
				for (t =  tk; t< tk + 1000*round(SBCTimes[k][j]); t+=1) 
					SBCWaveform[t]=AWGWaveformPoint_SBCooling(t, SBCAmplitudes[k], SBCFrequencies[k])
				endfor
				tk = t
				for (t =  tk; t<  tk + 1000*round(expt.ExOps[SBCIdx].SBCPumpingTime); t+=1) 
					SBCWaveform[t]=AWGWaveformPoint(t, SBCIdx, "Pumping", expt)
				endfor
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
function ConstructAWGWaveform(expt)

	STRUCT Experiment &expt
	NVAR shuttleDuration = root:ExpParams:SHUTTLE_DURATION
	Variable shuttleDur = 1000*round(shuttleDuration)
	SetDataFolder root:AWG
	WAVE SBCWaveform
	Variable t, tk, k, ExOpIdx = 0
	Variable durationIdx = 0				// Which control parameter in the ExOp definition is the duration
	Variable totalDuration = 0				// AWG waveform total duration
	Variable beginAWGWaveformFlag = 0	// Has AWG ExOp been found yet?
	Variable firstAWGExOp = 0			// Index of first AWG ExOp
	Variable lastAWGExOp = 0			// Index of last AWG ExOp

	
	Make/O/N=( expt.numExOps,1) ExOpDurations	// WAVE to store ExOp durations
	Make/O/T/N=( expt.numExOps,1) ExOpTypes	// WAVE to store ExOp types
	Make/O/T/N=( expt.numExOps,1) ExOpDevices	// WAVE to store ExOp devices
	Make/O/N=( expt.numExOps,1) ExOpPositions	// WAVE to store ExOp positions
	
	// Scan through ExOps and extract the necessary parameters
	for (ExOpIdx = 0; ExOpIdx < expt.numExOps; ExOpIdx +=1)
		ExOpTypes[ExOpIdx] = expt.ExOps[ExOpIdx].name
		durationIdx = WhichListItem("Duration", expt.ExOps[ExOpIdx].ControlParameters)
		if ( durationIdx == -1 && cmpstr(ExOpTypes[ExOpIdx], "SBCooling") != 0) 
			Abort "Experimental operation has no defined Duration control"
		else
			if (cmpstr(expt.ExOps[ExOpIdx].name, "SBCooling") == 0)
				CalculateSBCWaveform(expt)
				ExOpDurations[ExOpIdx] = 1000*expt.ExOps[ExOpIdx].SBCTotalTime
			else
				ExOpDurations[ExOpIdx] = 1000*str2num(StringFromList(durationIdx, expt.ExOps[ExOpIdx].Values))
			endif
			ExOpDevices[ExOpIdx] = expt.ExOps[ExOpIdx].device			
			ExOpPositions[ExOpIdx] = expt.ExOps[ExOpIdx].position
			
			// Find the first AWG chapter and only begin counting duration then
			if (cmpstr(ExOpDevices[ExOpIdx], "AWG") == 0)
				if (beginAWGWaveformFlag == 1)		// This check must come first!
					totalDuration += ExOpDurations[ExOpIdx]
					if (expt.ExOps[ExOpIdx].Shuttled == 1)
						totalDuration += shuttleDur
					endif
				endif	
				if ( beginAWGWaveformFlag == 0 )		// This check must come second!
					firstAWGExOp = ExOpIdx
					totalDuration += ExOpDurations[ExOpIdx]
					if (expt.ExOps[ExOpIdx].Shuttled == 1)
						totalDuration += shuttleDur
					endif
				endif
				lastAWGExOp = ExOpIdx
				beginAWGWaveformFlag = 1
			endif		
		endif		
	endfor
	
	Variable dur = round(totalDuration)			// Convert to nanoseconds

	Variable numPoints = (64)*(floor(dur/64)+1)	// Add padding so that waveform length is multiple of 64
	// Initialize AWG waveform to zero
	Make/O/N=(numPoints,1) AWGwaveform
	for (t = 0; t < numPoints; t+=1)
		AWGwaveform[t] = 0
	endfor
	
	// Iterate through the ExOps starting with the first AWG ExOp, constructing the waveform one point at a time
	Variable sbcIdx = 0
	t = 0
	for (ExOpIdx = firstAWGExOp; ExOpIdx < lastAWGExOp+1; ExOpIdx +=1)
		tk = t
		// If the ExOp is shuttled, add the shuttling duration
		if (expt.ExOps[ExOpIdx].Shuttled == 1)
			for (t =  tk; t< tk + shuttleDur; t+=1) 
				AWGwaveform[t]=AWGWaveformPoint(t, ExOpIdx, "Shuttled", expt)
			endfor
			tk = t
		endif
		if (cmpstr(expt.ExOps[ExOpIdx].name, "SBCooling") == 0)
			for (t =  tk; t< tk + ExOpDurations[ExOpIdx]; t+=1) 
				AWGwaveform[t]=SBCWaveform[sbcIdx]
				sbcIdx += 1
			endfor
		else
			for (t =  tk; t< tk + ExOpDurations[ExOpIdx]; t+=1) 
				AWGwaveform[t]=AWGWaveformPoint(t, ExOpIdx, ExOpTypes[ExOpIdx], expt)
			endfor
		endif
	endfor
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
		case "Rotation":	// Simple rotation
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
		case "SBCooling":	// Sideband cooling
			amplitudeIdx = WhichListItem("Amplitude", expt.ExOps[ExOpIdx].ControlParameters)
			amplitude = str2num(StringFromList(amplitudeIdx, expt.ExOps[ExOpIdx].Values))
			gateDetuningIdx = WhichListItem("GateDetuning", expt.ExOps[ExOpIdx].ControlParameters)
			gateDetuning = str2num(StringFromList(gateDetuningIdx, expt.ExOps[ExOpIdx].Values))	
			phaseIdx = WhichListItem("Phase", expt.ExOps[ExOpIdx].ControlParameters)
			phase = str2num(StringFromList(phaseIdx, expt.ExOps[ExOpIdx].Values))		
			return AWGWaveformPoint_MSGate(t, amplitude, gateDetuning, phase)
		default:	// Not an AWG ExOp						
			return 0
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
	
	return floor(   amp*(0.5+0.5*sin(2 * pi*t / period ))   )

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
	
	return floor(   amp*(0.5+0.5*sin(2 * pi*t / (period) + phase*pi/180))   )

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
	
	return floor(	ampRed*(0.5 + 0.5*cos(2 * pi*t / (periodRed) + phaseRed*pi/180)) 	+ ampBlue*(0.5 + 0.5*cos(2 * pi*t / (periodBlue) + phaseBlue*pi/180))	)

end

////_____________________________________________________________________________
////
//// AWGWaveformPoint_MSGate(t, carrierFreq, gateDetuning, ampRed, phaseRed, ampBlue, phaseBlue) 
//// returns the amplitude of a bichromatic waveform symmetrically-detuned from a carrier frequency
////_____________________________________________________________________________
////
//function AWGWaveformPoint_MSGate(t, carrierFreq, gateDetuning, ampRed, phaseRed, ampBlue, phaseBlue)
//
//	Variable t, carrierFreq, gateDetuning, ampRed, phaseRed, ampBlue, phaseBlue
//	Variable periodRed = 1000/(carrierFreq - gateDetuning)
//	Variable periodBlue = 1000/(carrierFreq + gateDetuning)
//	
//	// Coerce the amplitude to AWG bounds	
//	if (ampRed < 0)
//		ampRed = 0
//	else 
//		if (ampRed > 2047)
//			ampRed = 2047
//		endif
//	endif
//	if (ampBlue < 0)
//		ampBlue = 0
//	else 
//		if (ampBlue > 2047)
//			ampBlue = 2047
//		endif
//	endif
//	
//	return floor(	(ampRed - ampRed*cos(2 * pi*t / (periodRed) + phaseRed*pi/180)) 	+ (ampBlue - ampBlue*cos(2 * pi*t / (periodBlue) + phaseBlue*pi/180))	)
//
//end








//_____________________________________________________________________________
//
// AWGConstructWaveform() constructs the waveform, one point per nanosecond, 
// storing it as a global wave. The waveform segments are specified in the WAVE
// AWGExOpList.
//_____________________________________________________________________________
//
//function AWGConstructWaveform()
//	
//	Variable t, k, tk
//
//	NewDataFolder/O/S root:AWG
//	WAVE AWGExOpList = root:AWG:AWGExOpList	// AWG experimental operations
//	
//	Variable duration = 0						// microseconds
//	Variable	numExOps						// number of AWG experimental operations
//	numExOps = DimSize(AWGExOpList, 0)
//	Make/O/N=(numExOps,1) ExOpDurations	// WAVE to store ExOp durations
//	Make/O/N=(numExOps,1) ExOpTypes		// WAVE to store ExOp types
//	
//	for (k = 0; k < numExOps; k+=1)
//		duration += AWGExOpList[k][1]
//		ExOpDurations[k] = 1000*AWGExOpList[k][1]
//		ExOpTypes[k] = AWGExOpList[k][0]
//	endfor
//	
//	Variable dur = round(1000*duration)			// Convert to nanoseconds
//	Variable numPoints = (64)*(floor(dur/64)+1)	// Add padding so that waveform length is multiple of 64
//	
//	// Initialize AWG waveform to zero
//	Make/O/N=(numPoints,1) AWGwaveform
//	for (k = 0; k < numPoints; k+=1)
//		AWGwaveform[k] = 0
//	endfor
//	
//	// Iterate through the ExOps, constructing the waveform one point at a time
//	t = 0
//	for (k = 0; k < numExOps; k+=1)
//	tk = t
//		for (t =  tk; t< tk + ExOpDurations[k]; t+=1) 
//			AWGwaveform[t]=AWGWaveformPoint(t, k, ExOpTypes[k])
//		endfor
//	endfor
//	
//end