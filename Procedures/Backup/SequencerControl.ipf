#pragma rtGlobals=1		// Use modern global access method.

//_____________________________________________________________________________
//
//	There are three types of strings which the FPGA receives from the control program.  Each 
//	type of string begins with a different byte, so that	the FPGA knows which type it is.  
//	The three types are:
//	
//	m:	A string beginning with an m (0x6d) is a line in the experimental story.  The string contains 74 bits, not
//		counting the m at the beginning and the CR/LF at the end.  The first 10 bits are the line number of the line
//		(0,1,2,etc.).  This is used as the address in memory in which to store the line.  The next 32 bits
//		indicate which outputs are high and low, and which inputs to count.  The last 32 bits indicate how long to
//		remain on this line during the experiment before proceeding to the next line.
//	
//	r:	A string beginning with an r (0x72) contains 10 bits indicating how many lines there are total in the experimental story.
//	
//	n:	A string beginning with an n (0x6e) contains 24 bits.  The first 16 indicate how many repetitions of the experiment
//		to perform.  The next 8 indicate which counters to send back data for.  This string also generates a sequence start
//		pulse, allowing the FPGA to begin the experiments.
//
//	CR/LF: {0x0d,0x0a}
//_____________________________________________________________________________
//

//_____________________________________________________________________________
//
// sendSequence(sequence) writes the experimental sequence to the sequencer
//_____________________________________________________________________________
//
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
		
//		VDT2/P=$seq_p killio
//		VDTOpenPort2 $seq_p
//		VDTOperationsPort2 $seq_p
//		if(ComCheck()==0)
//		else
//			print "Error Writing to "+seq_p
//			return -1
//		endif
		VDTWriteBinaryWave2 writeWave
//		VDTClosePort2 $seq_p
		
		KillWaves writeWave
	endif
end

//_____________________________________________________________________________
//
// This function just returns the byte-significant byte from the right
//_____________________________________________________________________________
//
Function gb_seq(num, byte)
	Variable num, byte
	return floor(num / (256^(byte))) - 256*floor(num / (256^(byte+1)))
end

//_____________________________________________________________________________
//
// runSequence(reps, [recmask,tdc]) triggers the start of the sequencer output and reads the 
// collected data.
//_____________________________________________________________________________
//
function/WAVE runSequence(reps, [recmask,tdc])
	Variable reps
	Variable recmask,tdc
	
	SetDataFolder root:ExpParams
	SVAR SEQ_PORT
	String seq_p = SEQ_PORT
	SVAR TDC_PORT
	String tdc_p = TDC_PORT
	
	recmask = paramIsDefault(recmask) ? 0x00 : recmask
	tdc = paramIsDefault(tdc) ? 0 : tdc
	Make/B/U/O writeWave = {0x06e, gb_seq(reps,1), gb_seq(reps,0), gb_seq(recmask,3), 0x0d, 0x0a}
	
	Variable numChannels = 0
	variable i
	for(i=0; i<32; i+=1)
		numChannels += (recmask / 2^i) & 0x01
	EndFor
	
	// If the TDC is enabled, we open it beforehand since the buffer needs to be opened
//	If(TDC)
		//VDT2/P=$tdc_p baud=230400,stopbits=2,killio
//		VDTOpenPort2 $tdc_p
//	endif
	
//	VDT2/P=$seq_p killio
//	VDTOpenPort2 $seq_p
//	VDTOperationsPort2 $seq_p
//	if(ComCheck()==0)
//		else
//			print "Error Writing to "+seq_p
//			wave error
//			error =-1
//			return error
//	endif
	VDTWriteBinaryWave2 writeWave	
	SetDataFolder root:Sequencer:Data
	Make/B/U/O/n=(numChannels,reps) data
	VDTReadBinaryWave2/B/TYPE=16/O=15 data
//	VDTClosePort2 $seq_p
	SetDataFolder root:Sequencer
	
	// TDC data comes in as 6 bytes in little endian. The last byte 
	If(TDC)
		Variable tdc_points
		VDTOperationsPort2 $tdc_p
		VDTGetStatus2 0, 0, 0
		tdc_points = V_VDT
		
		Make/o/n=(tdc_points) tdc_data_temp
		VDTReadBinaryWave2/B/TYPE=0x48/O=1 tdc_data_temp
		VDTClosePort2 $tdc_p
		Make/o/n=(tdc_points/6) tdc_data
		tdc_data = tdc_data_temp[6*p] + tdc_data_temp[6*p+1]*(2^8) + tdc_data_temp[6*p+2]*(2^8)^2 + tdc_data_temp[6*p+3]*(2^8)^3 + tdc_data_temp[6*p+4]*(2^8)^4 + (tdc_data_temp[6*p+5] & 0x1F)*(2^8)^5
		print tdc_data
	endif
	
	KillWaves writeWave

	return data
end

//_____________________________________________________________________________
//
// seqHist(bins,dataWave)
//_____________________________________________________________________________
//
Function seqHist(bins,dataWave)	// Need to be in the Data folder when calling this function
	Variable bins
	Wave	dataWave
	SetDataFolder root:Sequencer:Data		
	
	Make/N=(bins)/O dataWave_Hist
	//Histogram/B={0,1,100} dataWave,data_Hist
	Histogram/B=1 dataWave,dataWave_Hist
	Display dataWave_Hist
end