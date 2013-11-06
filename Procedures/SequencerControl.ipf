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

function/WAVE runSequence(reps, [recmask,tdc])
	Variable reps
	Variable recmask,tdc
	recmask = paramIsDefault(recmask) ? 0x00 : recmask
	tdc = paramIsDefault(tdc) ? 0 : tdc
	Make/B/U/O writeWave = {0x06e, gb_seq(reps,1), gb_seq(reps,0), gb_seq(recmask,3), 0x0d, 0x0a}
//	VDTOperationsPort2 COM4
//	VDTWriteBinaryWave2 writeWave\
	print "TDC = "+num2str(tdc)
	
	Variable numChannels = 0
	variable i
	for(i=0; i<32; i+=1)
		numChannels += (recmask / 2^i) & 0x01
	EndFor
	If(TDC)
		Make/o/n=6 tdc_data_temp
//		Variable n
		VDT2/P=COM7 baud=230400,stopbits=2,killio
		VDTOpenPort2 COM7
		VDTOperationsPort2 COM7
		VDTReadBinaryWave2/B/TYPE=16/O=5 tdc_data_temp
//		VDTReadWave2/O=5 tdc_data_temp
//		VDTRead2/O=5 n
//		VDTGetStatus2 0,1,0
		VDTClosePort2 COM7
		print tdc_data_temp
//		print n
//		Print V_VDT
	endif
		
	VDTOperationsPort2 COM4
	VDTWriteBinaryWave2 writeWave	
	SetDataFolder root:Sequencer:Data
	Make/B/U/O/n=(numChannels,reps) data
	VDTReadBinaryWave2/B/TYPE=16/O=5 data
	SetDataFolder root:Sequencer

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