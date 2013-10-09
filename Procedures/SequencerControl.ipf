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
	
	SetDataFolder root:Sequencer:Data
	
	if(DimSize(sequence,0)>0) 
		// Check Verilog file for command documentation
		Make/B/U/O/n=0 writeWave
		Variable i
		for(i=0; i<DimSize(sequence,0); i+=1)
			writeWave[13*i] = {0x6d, gb_seq(i,1),gb_seq(i,0), gb_seq(sequence[i][0],3),gb_seq(sequence[i][0],2),gb_seq(sequence[i][0],1),gb_seq(sequence[i][0],0), gb_seq(sequence[i][1],3),gb_seq(sequence[i][1],2),gb_seq(sequence[i][1],1),gb_seq(sequence[i][1],0),0x0d,0x0a}
		endfor
		writeWave[13*i] = {0x72, gb_seq((i-1),1),gb_seq((i-1),0)} //sets max address to run to, counter adds 1 at the end that we need to take out
		VDTOperationsPort2 COM4
		VDTWriteBinaryWave2 writeWave
	endif
end

// This function just returns the byte-significant byte from the right
Function gb_seq(num, byte)
	Variable num, byte
	return floor(num / (256^(byte))) - 256*floor(num / (256^(byte+1)))
end

function/WAVE runSequence(reps, [recmask])
	Variable reps
	Variable recmask
	recmask = paramIsDefault(recmask) ? 0x00 : recmask
	
	Make/B/U/O writeWave = {0x06e, gb_seq(reps,1), gb_seq(recmask,0), 0xFF, 0x0d, 0x0a}
	VDTOperationsPort2 COM4
	VDTWriteBinaryWave2 writeWave
	
	Variable numChannels = 0
	variable i
	for(i=0; i<8; i+=1)
		numChannels += (recmask / 2^i) & 0x01
	EndFor
	Make/B/U/O/n=(numChannels,reps) data
	VDTReadBinaryWave2/B/TYPE=16 data
	
	return data
end