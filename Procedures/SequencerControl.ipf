#pragma rtGlobals=1		// Use modern global access method.

//--------------------------------------------------------------

//--------------------------------------------------------------
//
//                        UI FUNCTIONS
//
//--------------------------------------------------------------

//Function sendSequence()
//	SetDataFolder root:Sequencer:Data
//	Wave PulseProgram
//	
//	if(DimSize(PulseProgram,0)>0)
//		print "writing!"
//		// Check Verilog file for command documentation
//		Make/B/U/O/n=0 WriteWave
//		Variable i
//		for(i=0; i<DimSize(PulseProgram,0); i+=1)
//			WriteWave[13*i] = {0x6d, gb_seq(i,1),gb_seq(i,0), gb_seq(PulseProgram[i][0],3),gb_seq(PulseProgram[i][0],2),gb_seq(PulseProgram[i][0],1),gb_seq(PulseProgram[i][0],0), gb_seq(PulseProgram[i][1],3),gb_seq(PulseProgram[i][1],2),gb_seq(PulseProgram[i][1],1),gb_seq(PulseProgram[i][1],0),0x0d,0x0a}
//		endfor
//		WriteWave[13*i] = {0x72, gb_seq((i-1),1),gb_seq((i-1),0)} //sets max address to run to, counter adds 1 at the end that we need to take out
//		VDTOperationsPort2 COM7
//		VDTWriteBinaryWave2 WriteWave
//	endif
//	
//end
//
//// This function just returns the byte-significant byte from the right
//Function gb_seq(num, byte)
//	Variable num, byte
//	return floor(num / (256^(byte))) - 256*floor(num / (256^(byte+1)))
//end
//
//Function/WAVE runSequence(reps)
//	Variable reps
//	SetDataFolder root:Sequencer:Data	
//					
//	VDTOperationsPort2 COM7	
//
//	Make/B/U/O WriteWave = {0x06e, gb_seq(reps,1), gb_seq(reps,0), 0xFF, 0x0d, 0x0a}
//	VDTWriteBinaryWave2 WriteWave
//	//Make/B/U/O/n=(reps) data_01
//	//VDTReadBinaryWave2/B/TYPE=16 data_01
//
//	SetDataFolder root:Sequencer
//
//end
//
//Function seqHist(bins,dataWave)	// Need to be in the Data folder when calling this function
//	Variable bins
//	Wave	dataWave
//	SetDataFolder root:Sequencer:Data		
//	
//	Make/N=(bins)/O dataWave_Hist;DelayUpdate
//	Histogram/B={0,1,100} data,data_Hist
//end

function sendSequence(sequence)
	Wave sequence
	
	SetDataFolder root:ExpParams
	SVAR SEQ_PORT
	String seq_p = SEQ_PORT
	
	SetDataFolder root:Sequencer:Data
	
	if(DimSize(sequence,0)>0) 
		// Check Verilog file for command documentation
		Make/B/U/O/n=0 writeWave
		Variable i
		for(i=0; i<DimSize(sequence,0); i+=1)
			writeWave[13*i] = {0x6d, gb_seq(i,1),gb_seq(i,0), gb_seq(sequence[i][0],3),gb_seq(sequence[i][0],2),gb_seq(sequence[i][0],1),gb_seq(sequence[i][0],0), gb_seq(sequence[i][1],3),gb_seq(sequence[i][1],2),gb_seq(sequence[i][1],1),gb_seq(sequence[i][1],0),0x0d,0x0a}
		endfor
		writeWave[13*i] = {0x72, gb_seq((i-1),1),gb_seq((i-1),0)} //sets max address to run to, counter adds 1 at the end that we need to take out
		
		VDT2/P=COM12 baud=230400,stopbits=2,killio
		VDTOpenPort2 $seq_p
		VDTOperationsPort2 $seq_p
		VDTWriteBinaryWave2 writeWave
		VDTClosePort2 $seq_p
		
		//KillWaves writeWave
	endif
end

// This function just returns the byte-significant byte from the right
Function gb_seq(num, byte)
	Variable num, byte
	return floor(num / (256^(byte))) - 256*floor(num / (256^(byte+1)))
end

function/WAVE runSequence(reps, [recmask,tdc])
	Variable reps
	Variable recmask,tdc
	
	SetDataFolder root:ExpParams
	SVAR SEQ_PORT
	String seq_p = SEQ_PORT
	
	recmask = paramIsDefault(recmask) ? 0x00 : recmask
	tdc = paramIsDefault(tdc) ? 0 : tdc
	Make/B/U/O writeWave = {0x06e, gb_seq(reps,1), gb_seq(reps,0), gb_seq(recmask,3), 0x0d, 0x0a}
//	VDTOperationsPort2 COM4
//	VDTWriteBinaryWave2 writeWave\
	
	Variable numChannels = 0
	variable i
	for(i=0; i<32; i+=1)
		numChannels += (recmask / 2^i) & 0x01
	EndFor
	
	// If the TDC is enabled, we open it beforehand since the buffer needs to be opened
	If(TDC)
		VDT2/P=COM7 baud=230400,stopbits=2,killio
		VDTOpenPort2 COM7
	endif
	
	VDT2/P=$seq_p baud=230400,stopbits=2,killio
	VDTOpenPort2 $seq_p
	VDTOperationsPort2 $seq_p
	VDTWriteBinaryWave2 writeWave	
	SetDataFolder root:Sequencer:Data
	Make/Y=(0x50)/U/O/n=(numChannels,reps) data
	VDTReadBinaryWave2/B/TYPE=(0x50)/O=5 data
	VDTClosePort2 $seq_p
	SetDataFolder root:Sequencer
	
	// TDC data comes in as 6 bytes in little endian. The last byte 
	If(TDC)
		Variable tdc_points
		VDTOperationsPort2 COM7
		VDTGetStatus2 0, 0, 0
		tdc_points = V_VDT
		
		Make/o/n=(tdc_points) tdc_data_temp
		VDTReadBinaryWave2/B/TYPE=0x48/O=1 tdc_data_temp
		VDTClosePort2 COM7
		Make/o/n=(tdc_points/6) tdc_data
		tdc_data = tdc_data_temp[6*p] + tdc_data_temp[6*p+1]*(2^8) + tdc_data_temp[6*p+2]*(2^8)^2 + tdc_data_temp[6*p+3]*(2^8)^3 + tdc_data_temp[6*p+4]*(2^8)^4 + (tdc_data_temp[6*p+5] & 0x1F)*(2^8)^5
		print tdc_data
	endif
	
	//KillWaves writeWave

	return data
end

Function seqHist(bins,dataWave)	// Need to be in the Data folder when calling this function
	Variable bins
	Wave	dataWave
	SetDataFolder root:Sequencer:Data		

	Make/N=(bins)/O dataWave_Hist
	//Histogram/B={0,1,100} dataWave,data_Hist
	Histogram/B=1 dataWave,dataWave_Hist
	Display dataWave_Hist
end

//Function/WAVE runSequence(reps)
//	Variable reps
//	SetDataFolder root:Sequencer:Data	
//					
//	VDTOperationsPort2 COM7	
//
//	Make/B/U/O WriteWave = {0x06e, gb_seq(reps,1), gb_seq(reps,0), 0xFF, 0x0d, 0x0a}
//	VDTWriteBinaryWave2 WriteWave
//	//Make/B/U/O/n=(reps) data_01
//	//VDTReadBinaryWave2/B/TYPE=16 data_01
//
//	SetDataFolder root:Sequencer
//
//end
//
//Function seqHist(bins,dataWave)	// Need to be in the Data folder when calling this function
//	Variable bins
//	Wave	dataWave
//	SetDataFolder root:Sequencer:Data		
//	
//	Make/N=(bins)/O dataWave_Hist;DelayUpdate
//	Histogram/B={0,1,100} data,data_Hist
//end