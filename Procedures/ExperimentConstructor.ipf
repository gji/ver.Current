#pragma rtGlobals=1

//_____________________________________________________________________________
//
// Define the Experimental Operation data structure
//_____________________________________________________________________________
//
Structure ExOp
	String name
	String description
	String device
	String ControlParameters
	String Values		// Current values of control parameters. Initially the defaults.
	String ScannableParameters
	Variable numScanParams
	String MinVal
	String MaxVal
	String MinInc
	Variable Scanned
	Variable ScanParameter
	Variable ScanStart
	Variable ScanStop
	Variable ScanInc		
	Variable Position		// Specifies voltage set to apply
	Variable Shuttled		// Is the previous ExOp at a different position? 
	String SBCFrequencies
	String SBCAmplitudes
	String SBCTimes
	String SBCCycles
	Variable SBCPumpingTime
	Variable SBCTotalTime
EndStructure

//_____________________________________________________________________________
//
// Define the Experiment data structure
//_____________________________________________________________________________
//
Structure Experiment
	Variable numExOps
	Variable exptsPerPoint
	Variable pointsToAverage
	STRUCT ExOp ExOps[100]
EndStructure

//_____________________________________________________________________________
//
// Define the ExOpDefinitions data structure that allows for modular modification of ExOps and
// specifies their parameter values
//_____________________________________________________________________________
//
Structure ExOpDefinitions
	STRUCT ExOp Cool
	STRUCT ExOp Pump
	STRUCT ExOp Detect
	STRUCT ExOp FlrDetect
	STRUCT ExOp Rotation
	STRUCT ExOp MSGate
	STRUCT ExOp SBCooling
	STRUCT ExOp Delay
	STRUCT ExOp Microwave
	STRUCT ExOp AWGRotation	
EndStructure

//_____________________________________________________________________________
//
// Specify the default parameters for the various ExOp types
//_____________________________________________________________________________
//
function GetExOpDefinitions(ExOpDefs)
	STRUCT ExOpDefinitions &ExOpDefs
	NVAR CUR_POS	=	root:ExpParams:CUR_POS
		
	ExOpDefs.Pump.name = "Pump"
	ExOpDefs.Pump.description = "Optical Pumping"
	ExOpDefs.Pump.device = "DDS0"
	ExOpDefs.Pump.ControlParameters = "Duration;Amplitude;Frequency;"
	ExOpDefs.Pump.Values = "5;100;200;"
	ExOpDefs.Pump.ScannableParameters = "1;0;1;"
	ExOpDefs.Pump.MinVal = "0.1;0;100;"
	ExOpDefs.Pump.MaxVal = "1E8;100;400;"
	ExOpDefs.Pump.MinInc = "0.1;1;0.01;"
	ExOpDefs.Pump.ScanParameter = 0
	ExOpDefs.Pump.Position = CUR_POS	
	ExOpDefs.SBCooling.SBCPumpingTime = 0
	ExOpDefs.SBCooling.SBCTotalTime = 0
	ExOpDefs.SBCooling.SBCFrequencies = ""
	ExOpDefs.SBCooling.SBCAmplitudes = ""
	ExOpDefs.SBCooling.SBCTimes = ""
	ExOpDefs.SBCooling.SBCCycles = ""
	
	ExOpDefs.Cool.name = "Cool"
	ExOpDefs.Cool.description = "Doppler Cooling"
	ExOpDefs.Cool.device = "DDS2"
	ExOpDefs.Cool.ControlParameters = "Duration;Amplitude;Frequency;"
	ExOpDefs.Cool.Values = "100;100;200;"
	ExOpDefs.Cool.ScannableParameters = "1;0;1;"
	ExOpDefs.Cool.MinVal = "0.1;0;100;"
	ExOpDefs.Cool.MaxVal = "1E8;100;400;"
	ExOpDefs.Cool.MinInc = "0.1;1;0.01;"
	ExOpDefs.Cool.ScanParameter = 0
	ExOpDefs.Cool.Position = CUR_POS	
	ExOpDefs.SBCooling.SBCPumpingTime = 0
	ExOpDefs.SBCooling.SBCTotalTime = 0
	ExOpDefs.SBCooling.SBCFrequencies = ""
	ExOpDefs.SBCooling.SBCAmplitudes = ""
	ExOpDefs.SBCooling.SBCTimes = ""
	ExOpDefs.SBCooling.SBCCycles = ""
	
	ExOpDefs.Microwave.name = "Microwave"
	ExOpDefs.Microwave.description = "Microwave qubit rotation"
	ExOpDefs.Microwave.device = "AWG"
	ExOpDefs.Microwave.ControlParameters = "Duration;Amplitude;Frequency;Phase;"
	ExOpDefs.Microwave.Values = "10;1023;250;0;"
	ExOpDefs.Microwave.ScannableParameters = "1;1;1;1;"
	ExOpDefs.Microwave.MinVal = "10;0;100;0;"
	ExOpDefs.Microwave.MaxVal = "1E8;2047;400;359;"
	ExOpDefs.Microwave.MinInc = "0.5;1;0.01;1;"
	ExOpDefs.Microwave.ScanParameter = 0	
	ExOpDefs.SBCooling.SBCPumpingTime = 0
	ExOpDefs.SBCooling.SBCTotalTime = 0
	ExOpDefs.SBCooling.SBCFrequencies = ""
	ExOpDefs.SBCooling.SBCAmplitudes = ""
	ExOpDefs.SBCooling.SBCTimes = ""
	ExOpDefs.SBCooling.SBCCycles = ""
	
	ExOpDefs.AWGRotation.name = "AWGRotation"
	ExOpDefs.AWGRotation.description = "AWG rotation"
	ExOpDefs.AWGRotation.device = "AWG"
	ExOpDefs.AWGRotation.ControlParameters = "Duration;Amplitude;Frequency;Phase;"
	ExOpDefs.AWGRotation.Values = "1;2047;250;0;"
	ExOpDefs.AWGRotation.ScannableParameters = "1;1;1;1;"
	ExOpDefs.AWGRotation.MinVal = "0.1;0;10;0;"
	ExOpDefs.AWGRotation.MaxVal = "100000;4094;350;359;"
	ExOpDefs.AWGRotation.MinInc = "0.5;1;0.01;1;"
	ExOpDefs.AWGRotation.ScanParameter = 0	
	ExOpDefs.SBCooling.SBCPumpingTime = 0
	ExOpDefs.SBCooling.SBCTotalTime = 0
	ExOpDefs.SBCooling.SBCFrequencies = ""
	ExOpDefs.SBCooling.SBCAmplitudes = ""
	ExOpDefs.SBCooling.SBCTimes = ""
	ExOpDefs.SBCooling.SBCCycles = ""
	
	ExOpDefs.Detect.name = "Detect"
	ExOpDefs.Detect.description = "State Detection"
	ExOpDefs.Detect.device = "DDS0"
	ExOpDefs.Detect.ControlParameters = "Duration;Amplitude;Frequency;"
	ExOpDefs.Detect.Values = "10;100;300;"
	ExOpDefs.Detect.ScannableParameters = "1;0;1;"
	ExOpDefs.Detect.MinVal = "0.1;0;100;"
	ExOpDefs.Detect.MaxVal = "1E8;100;400;"
	ExOpDefs.Detect.MinInc = "0.1;1;0.01;"
	ExOpDefs.Detect.ScanParameter = 0
	ExOpDefs.Detect.Position = CUR_POS	
	ExOpDefs.SBCooling.SBCPumpingTime = 0
	ExOpDefs.SBCooling.SBCTotalTime = 0
	ExOpDefs.SBCooling.SBCFrequencies = ""
	ExOpDefs.SBCooling.SBCAmplitudes = ""
	ExOpDefs.SBCooling.SBCTimes = ""
	ExOpDefs.SBCooling.SBCCycles = ""
	
	ExOpDefs.Delay.name = "Delay"
	ExOpDefs.Delay.description = "Delay"
	ExOpDefs.Delay.device = ""
	ExOpDefs.Delay.ControlParameters = "Duration;"
	ExOpDefs.Delay.Values = "0.1;"
	ExOpDefs.Delay.ScannableParameters = "1;"
	ExOpDefs.Delay.MinVal = "0.1;"
	ExOpDefs.Delay.MaxVal = "1E8;"
	ExOpDefs.Delay.MinInc = "0.1;"
	ExOpDefs.Delay.ScanParameter = 0
	ExOpDefs.Delay.Position = CUR_POS	
	ExOpDefs.SBCooling.SBCPumpingTime = 0
	ExOpDefs.SBCooling.SBCTotalTime = 0
	ExOpDefs.SBCooling.SBCFrequencies = ""
	ExOpDefs.SBCooling.SBCAmplitudes = ""
	ExOpDefs.SBCooling.SBCTimes = ""
	ExOpDefs.SBCooling.SBCCycles = ""
	
	ExOpDefs.FlrDetect.name = "Flourescence Detect"
	ExOpDefs.FlrDetect.description = "Flourescence Detection"
	ExOpDefs.FlrDetect.device = "DDS1"
	ExOpDefs.FlrDetect.ControlParameters = "Duration;Amplitude;Frequency;"
	ExOpDefs.FlrDetect.Values = "100;100;200;"
	ExOpDefs.FlrDetect.ScannableParameters = "1;0;1;"
	ExOpDefs.FlrDetect.MinVal = "0.1;0;100;"
	ExOpDefs.FlrDetect.MaxVal = "1E8;100;400;"
	ExOpDefs.FlrDetect.MinInc = "0.1;1;0.01;"
	ExOpDefs.FlrDetect.ScanParameter = 0
	ExOpDefs.FlrDetect.Position = CUR_POS	
	ExOpDefs.SBCooling.SBCPumpingTime = 0
	ExOpDefs.SBCooling.SBCTotalTime = 0
	ExOpDefs.SBCooling.SBCFrequencies = ""
	ExOpDefs.SBCooling.SBCAmplitudes = ""
	ExOpDefs.SBCooling.SBCTimes = ""
	ExOpDefs.SBCooling.SBCCycles = ""
	
	ExOpDefs.MSGate.name = "MSGate"
	ExOpDefs.MSGate.description = "Constant amplitude MS gate"
	ExOpDefs.MSGate.device = "AWG"
	ExOpDefs.MSGate.ControlParameters = "Duration;Amplitude;GateDetuning;Phase;"
	ExOpDefs.MSGate.Values = "10;2047;1;0;"
	ExOpDefs.MSGate.ScannableParameters = "1;1;1;0;"
	ExOpDefs.MSGate.MinVal = "10;0;0.001;0;"
	ExOpDefs.MSGate.MaxVal = "1E8;2047;10;359;"
	ExOpDefs.MSGate.MinInc = "0.1;1;0.001;1;"
	ExOpDefs.MSGate.ScanParameter = 0	
	ExOpDefs.SBCooling.SBCPumpingTime = 0
	ExOpDefs.SBCooling.SBCTotalTime = 0
	ExOpDefs.SBCooling.SBCFrequencies = ""
	ExOpDefs.SBCooling.SBCAmplitudes = ""
	ExOpDefs.SBCooling.SBCTimes = ""
	ExOpDefs.SBCooling.SBCCycles = ""
	
	ExOpDefs.SBCooling.name = "SBCooling"
	ExOpDefs.SBCooling.description = "Sideband Cooling "
	ExOpDefs.SBCooling.device = "AWG"
	ExOpDefs.SBCooling.ControlParameters = ""
	ExOpDefs.SBCooling.Values = ""
	ExOpDefs.SBCooling.ScannableParameters = ""
	ExOpDefs.SBCooling.MinVal = ";"
	ExOpDefs.SBCooling.MaxVal = ""
	ExOpDefs.SBCooling.MinInc = ""
	ExOpDefs.SBCooling.ScanParameter = 0
	ExOpDefs.SBCooling.Position = CUR_POS	
	ExOpDefs.SBCooling.SBCPumpingTime = 5
	ExOpDefs.SBCooling.SBCTotalTime = 1
	ExOpDefs.SBCooling.SBCFrequencies = ""
	ExOpDefs.SBCooling.SBCAmplitudes = ""
	ExOpDefs.SBCooling.SBCTimes = ""
	ExOpDefs.SBCooling.SBCCycles = ""
end

//_____________________________________________________________________________
//
//	Constructs and returns (by reference) an Experiment structure with operations specified in  
//	the input Sequence WAVE
//_____________________________________________________________________________
//
function BuildExperiment(Sequence, expt)
	STRUCT Experiment &expt
	WAVE/T Sequence
	STRUCT ExOpDefinitions ExOpDefs
	GetExOpDefinitions(ExOpDefs)
	Variable k
	expt.numExOps = numpnts(Sequence)
	expt.exptsPerPoint = 1
	expt.pointsToAverage = 1
	
	for (k=0;k<expt.numExOps;k+=1)
		strswitch(Sequence[k])	// string switch
			case "Cool":
				expt.ExOps[k] = ExOpDefs.Cool
				break
			case "Pump":
				expt.ExOps[k] = ExOpDefs.Pump
				break
			case "Rotation":
				expt.ExOps[k] = ExOpDefs.Rotation
				break
			case "AWGRotation":
				expt.ExOps[k] = ExOpDefs.AWGRotation
				break
			case "State Detection":
				expt.ExOps[k] = ExOpDefs.Detect
				break
			case "Flourescence Detection":
				expt.ExOps[k] = ExOpDefs.FlrDetect
				break
			case "MSGate":
				expt.ExOps[k] = ExOpDefs.MSGate
				break
			case "SBCooling":
				expt.ExOps[k] = ExOpDefs.SBCooling
				break
			case "Delay":
				expt.ExOps[k] = ExOpDefs.Delay
				break
			case "Microwave":
				expt.ExOps[k] = ExOpDefs.Microwave
				break					
			default:							// optional default expression executed
				break						// when no case matches
		endswitch
	endfor
end

//_____________________________________________________________________________
//
//	Wrapper function for StringFromList that returns the parameter in a string "array"
//_____________________________________________________________________________
//
function/S ExOpElement(str,idx)
	String str
	Variable idx
	return StringFromList(idx,str,";")
end

//_____________________________________________________________________________
//
//	Export data in an Experiment structure to a JSON-formatted human readable file on disk
//_____________________________________________________________________________
//
function ExportExptToJSONFile(expt, filename)
	STRUCT Experiment &expt
	String filename
	// Create path and filename for exported Experiment structure
	PathInfo home				// Save home folder of unpacked experiment folder to S_path
	String homeFolder = S_path	// Save path to persistent local variable
	NewPath/O/C/Q/Z TempPath, homeFolder+"Data:"
	// Create/open the file for editing
	Variable f1 //make refNum variable
	Open/P=TempPath f1 as filename //create and open file
	
	// Iterate through the Experiment structure data fields, construct the output string in 
	// JSON format, and output to the file
	Variable ExOpIdx
	String JSONstr = ""
	String CR = "\r"
	String TAB = "\t"
	String Q = ""
	JSONstr += "{"+CR
	JSONstr += TAB+Q+"numExOps"+Q+": "+num2str(expt.numExOps)+","+CR
	JSONstr += TAB+Q+"exptsPerPoint"+Q+": "+num2str(expt.exptsPerPoint)+","+CR
	JSONstr += TAB+Q+"pointsToAverage"+Q+": "+num2str(expt.pointsToAverage)+","+CR
	JSONstr += TAB+Q+"ExOps"+Q+": ["+CR
	for (ExOpIdx = 0; ExOpIdx < expt.numExOps; ExOpIdx +=1)
		if (ExOpIdx > 0)
			JSONstr += ","+CR
		endif
		JSONstr += TAB+TAB+"{"+ CR
		JSONstr += TAB+TAB+TAB+Q+"Name"+Q+": "+ Q+expt.ExOps[ExOpIdx].name+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"Description"+Q+": "+Q+ expt.ExOps[ExOpIdx].description+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"Device"+Q+": "+ Q+expt.ExOps[ExOpIdx].device+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"ControlParameters"+Q+": "+ Q+expt.ExOps[ExOpIdx].ControlParameters+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"Values"+Q+": "+ Q+expt.ExOps[ExOpIdx].Values+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"ScannableParameters"+Q+": "+ Q+expt.ExOps[ExOpIdx].ScannableParameters+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"numScanParams"+Q+": "+ num2str(expt.ExOps[ExOpIdx].numScanParams)+","+CR
		JSONstr += TAB+TAB+TAB+Q+"MinVal"+Q+": "+ Q+expt.ExOps[ExOpIdx].MinVal+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"MaxVal"+Q+": "+ Q+expt.ExOps[ExOpIdx].MaxVal+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"MinInc"+Q+": "+Q+ expt.ExOps[ExOpIdx].MinInc+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"Scanned"+Q+": "+ num2str(expt.ExOps[ExOpIdx].Scanned)+","+CR
		JSONstr += TAB+TAB+TAB+Q+"ScanParameter"+Q+": "+ num2str(expt.ExOps[ExOpIdx].ScanParameter)+","+CR
		JSONstr += TAB+TAB+TAB+Q+"ScanStart"+Q+": "+ num2str(expt.ExOps[ExOpIdx].ScanStart)+","+CR
		JSONstr += TAB+TAB+TAB+Q+"ScanStop"+Q+": "+ num2str(expt.ExOps[ExOpIdx].ScanStop)+","+CR
		JSONstr += TAB+TAB+TAB+Q+"ScanInc"+Q+": "+ num2str(expt.ExOps[ExOpIdx].ScanInc)+","+CR
		JSONstr += TAB+TAB+TAB+Q+"Position"+Q+": "+ num2str(expt.ExOps[ExOpIdx].Position)+","+CR
		JSONstr += TAB+TAB+TAB+Q+"Shuttled"+Q+": "+ num2str(expt.ExOps[ExOpIdx].Shuttled)+","+CR
		if (cmpstr(expt.ExOps[ExOpIdx].name, "SBCooling") == 0)
			JSONstr += TAB+TAB+TAB+Q+"SBCPumpingTime"+Q+": "+ num2str(expt.ExOps[ExOpIdx].SBCPumpingTime)+","+CR
			JSONstr += TAB+TAB+TAB+Q+"SBCTotalTime"+Q+": "+ num2str(expt.ExOps[ExOpIdx].SBCTotalTime)+","+CR
			JSONstr += TAB+TAB+TAB+Q+"SBCFrequencies"+Q+": "+ expt.ExOps[ExOpIdx].SBCFrequencies+","+CR
			JSONstr += TAB+TAB+TAB+Q+"SBCAmplitudes"+Q+": "+ expt.ExOps[ExOpIdx].SBCAmplitudes+","+CR
			JSONstr += TAB+TAB+TAB+Q+"SBCTimes"+Q+": "+ expt.ExOps[ExOpIdx].SBCTimes+","+CR	
			JSONstr += TAB+TAB+TAB+Q+"SBCCycles"+Q+": "+ expt.ExOps[ExOpIdx].SBCCycles+","+CR	
		endif		
		JSONstr += TAB+TAB+"}"
		// Output to file and clear the string because fprintf strings have limited length
		fprintf f1, "%s", JSONstr
		JSONstr = ""
	endfor
	JSONstr += CR+TAB+ "]"+CR
	JSONstr += "}"
	fprintf f1, "%s", JSONstr
	Close f1 //close file
end


//_____________________________________________________________________________
//
//	Export data in an Experiment structure to a JSON-formatted human readable string variable
//_____________________________________________________________________________
//
function/S ExportExptToJSONString(expt)
	STRUCT Experiment &expt
	
	// Iterate through the Experiment structure data fields, construct the output string in 
	// JSON format, and output to the file
	Variable ExOpIdx
	String JSONstr = ""
	String CR = "\r"
	String TAB = "\t"
	String Q = ""
	JSONstr += "{"+CR
	JSONstr += TAB+Q+"numExOps"+Q+": "+num2str(expt.numExOps)+","+CR
	JSONstr += TAB+Q+"exptsPerPoint"+Q+": "+num2str(expt.exptsPerPoint)+","+CR
	JSONstr += TAB+Q+"pointsToAverage"+Q+": "+num2str(expt.pointsToAverage)+","+CR
	JSONstr += TAB+Q+"ExOps"+Q+": ["+CR
	for (ExOpIdx = 0; ExOpIdx < expt.numExOps; ExOpIdx +=1)
		if (ExOpIdx > 0)
			JSONstr += ","+CR
		endif
		JSONstr += TAB+TAB+"{"+ CR
		JSONstr += TAB+TAB+TAB+Q+"Name"+Q+": "+ Q+expt.ExOps[ExOpIdx].name+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"Description"+Q+": "+Q+ expt.ExOps[ExOpIdx].description+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"Device"+Q+": "+ Q+expt.ExOps[ExOpIdx].name+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"ControlParameters"+Q+": "+ Q+expt.ExOps[ExOpIdx].ControlParameters+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"Values"+Q+": "+ Q+expt.ExOps[ExOpIdx].Values+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"ScannableParameters"+Q+": "+ Q+expt.ExOps[ExOpIdx].ScannableParameters+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"numScanParams"+Q+": "+ num2str(expt.ExOps[ExOpIdx].numScanParams)+","+CR
		JSONstr += TAB+TAB+TAB+Q+"MinVal"+Q+": "+ Q+expt.ExOps[ExOpIdx].MinVal+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"MaxVal"+Q+": "+ Q+expt.ExOps[ExOpIdx].MaxVal+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"MinInc"+Q+": "+Q+ expt.ExOps[ExOpIdx].MinInc+Q+","+CR
		JSONstr += TAB+TAB+TAB+Q+"Scanned"+Q+": "+ num2str(expt.ExOps[ExOpIdx].Scanned)+","+CR
		JSONstr += TAB+TAB+TAB+Q+"ScanParameter"+Q+": "+ num2str(expt.ExOps[ExOpIdx].ScanParameter)+","+CR
		JSONstr += TAB+TAB+TAB+Q+"ScanStart"+Q+": "+ num2str(expt.ExOps[ExOpIdx].ScanStart)+","+CR
		JSONstr += TAB+TAB+TAB+Q+"ScanStop"+Q+": "+ num2str(expt.ExOps[ExOpIdx].ScanStop)+","+CR
		JSONstr += TAB+TAB+TAB+Q+"ScanInc"+Q+": "+ num2str(expt.ExOps[ExOpIdx].ScanInc)+","+CR
		JSONstr += TAB+TAB+TAB+Q+"Position"+Q+": "+ num2str(expt.ExOps[ExOpIdx].Position)+","+CR
		JSONstr += TAB+TAB+TAB+Q+"Shuttled"+Q+": "+ num2str(expt.ExOps[ExOpIdx].Shuttled)+","+CR
		if (cmpstr(expt.ExOps[ExOpIdx].name, "SBCooling") == 0)
			JSONstr += TAB+TAB+TAB+Q+"SBCPumpingTime"+Q+": "+ num2str(expt.ExOps[ExOpIdx].SBCPumpingTime)+","+CR
			JSONstr += TAB+TAB+TAB+Q+"SBCTotalTime"+Q+": "+ num2str(expt.ExOps[ExOpIdx].SBCTotalTime)+","+CR
			JSONstr += TAB+TAB+TAB+Q+"SBCFrequencies"+Q+": "+ expt.ExOps[ExOpIdx].SBCFrequencies+","+CR
			JSONstr += TAB+TAB+TAB+Q+"SBCAmplitudes"+Q+": "+ expt.ExOps[ExOpIdx].SBCAmplitudes+","+CR
			JSONstr += TAB+TAB+TAB+Q+"SBCTimes"+Q+": "+ expt.ExOps[ExOpIdx].SBCTimes+","+CR	
			JSONstr += TAB+TAB+TAB+Q+"SBCCycles"+Q+": "+ expt.ExOps[ExOpIdx].SBCCycles+","+CR	
		endif		
		JSONstr += TAB+TAB+"}"
	endfor
	JSONstr += CR+TAB+ "]"+CR
	JSONstr += "}"
	
	return JSONstr
end

//_____________________________________________________________________________
//
//	Import data in an Experiment structure from a JSON-formatted human readable file on disk
//_____________________________________________________________________________
//
function ImportExptFromJSONFile(expt, filename)
	STRUCT Experiment &expt
	String filename
	Variable len
	// Create path and filename for exported Experiment structure
	PathInfo home				// Save home folder of unpacked experiment folder to S_path
	String homeFolder = S_path	// Save path to persistent local variable
	NewPath/O/C/Q/Z TempPath, homeFolder+"..:..:Data:"

	String JSONstr = ""

	// Create/open the file for editing
	Variable refNum //make refNum variable
	Open/R/P=TempPath refNum as filename //create and open file
	if (refNum == 0)
		Abort "Select valid filename"
	endif
	String inputBuffer = ""
	do
		FReadLine refNum, inputBuffer
		len = strlen(inputBuffer)
		if (len == 0)
			break						// No more lines to be read
		endif
		JSONstr += inputBuffer
	while(1)
	Close refNum //close file
	

	Variable numExOps
	Variable exptsPerPoint
	Variable pointsToAverage
	String query1 
	String query2
	Variable p1, p2
	query1 = "numExOps:"
	p1 = strsearch(JSONstr,query1, 0)
	query2 = ","
	p2 = strsearch(JSONstr,query2, p1 + strlen(query1))
	expt.numExOps = str2num(JSONstr[p1 + strlen(query1), p2-1])
	
	query1 = "exptsPerPoint:"
	p1 = strsearch(JSONstr,query1, 0)
	query2 = ","
	p2 = strsearch(JSONstr,query2, p1 + strlen(query1))
	expt.exptsPerPoint = str2num(JSONstr[p1 + strlen(query1), p2-1])
	
	query1 = "pointsToAverage:"
	p1 = strsearch(JSONstr,query1, 0)
	query2 = ","
	p2 = strsearch(JSONstr,query2, p1 + strlen(query1))
	expt.pointsToAverage = str2num(JSONstr[p1 + strlen(query1), p2-1])
	
	//printf "%g, %g, %g\r", numExOps, exptsPerPoint, pointsToAverage
	
	String ExOps
	String ExOp
	query1 = "["
	p1 = strsearch(JSONstr,query1, 0)
	query2 = "]"
	p2 = strsearch(JSONstr,query2, p1 + strlen(query1))
	ExOps = JSONstr[p1 + strlen(query1), p2-1]
	Variable ExOpIdx
	Variable strPos = 0
	for (ExOpIdx = 0; ExOpIdx < expt.numExOps; ExOpIdx +=1)	
		query1 = "{"
		p1 = strsearch(ExOps,query1, strPos)
		query2 = "}"
		p2 = strsearch(ExOps,query2, p1 + strlen(query1))
		strPos = p2 
		ExOp = ExOps[p1 + strlen(query1), p2-1]
		
		query1 = "Name: "
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].name = ExOp[p1 + strlen(query1), p2-1]
			
		query1 = "Description: "
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].description = ExOp[p1 + strlen(query1), p2-1]
	
		query1 = "Device: "
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].device = ExOp[p1 + strlen(query1), p2-1]
			
		query1 = "ControlParameters: "
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].ControlParameters = ExOp[p1 + strlen(query1), p2-1]

		query1 = "Values:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].values = ExOp[p1 + strlen(query1), p2-1]
			
		query1 = "ScannableParameters:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].ScannableParameters = ExOp[p1 + strlen(query1), p2-1]
	
		query1 = "numScanParams:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].numScanParams = str2num( ExOp[p1 + strlen(query1), p2-1] )
			
		query1 = "MinVal:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].MinVal = ExOp[p1 + strlen(query1), p2-1]
		
		query1 = "MaxVal:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].MaxVal = ExOp[p1 + strlen(query1), p2-1]
		
		query1 = "MinInc:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].MinInc = ExOp[p1 + strlen(query1), p2-1]		
			
		query1 = "Scanned:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].Scanned = str2num( ExOp[p1 + strlen(query1), p2-1] )

		query1 = "ScanParameter:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].ScanParameter = str2num( ExOp[p1 + strlen(query1), p2-1] )

		query1 = "ScanStart:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].ScanStart = str2num( ExOp[p1 + strlen(query1), p2-1] )

		query1 = "ScanStop:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].ScanStop = str2num( ExOp[p1 + strlen(query1), p2-1] )

		query1 = "ScanInc:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].ScanInc = str2num( ExOp[p1 + strlen(query1), p2-1] )

		query1 = "Position:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].Position = str2num( ExOp[p1 + strlen(query1), p2-1] )

		query1 = "Shuttled:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].Shuttled = str2num( ExOp[p1 + strlen(query1), p2-1] )
	
		query1 = "SBCTotalTime:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].SBCTotalTime = str2num( ExOp[p1 + strlen(query1), p2-1] )
		
		query1 = "SBCPumpingTime:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].SBCPumpingTime = str2num( ExOp[p1 + strlen(query1), p2-1] )
	endfor

end



//_____________________________________________________________________________
//
//	Import data in an Experiment structure from a JSON-formatted human readable Igor string
//	variable
//_____________________________________________________________________________
//
function ImportExptFromJSONString(expt, PathToSettingWave)
	STRUCT Experiment &expt
	String PathToSettingWave
	SVAR JSONstr = $(PathToSettingWave)

	Variable numExOps
	Variable exptsPerPoint
	Variable pointsToAverage
	String query1 
	String query2
	Variable p1, p2
	query1 = "numExOps:"
	p1 = strsearch(JSONstr,query1, 0)
	query2 = ","
	p2 = strsearch(JSONstr,query2, p1 + strlen(query1))
	expt.numExOps = str2num(JSONstr[p1 + strlen(query1), p2-1])
	
	query1 = "exptsPerPoint:"
	p1 = strsearch(JSONstr,query1, 0)
	query2 = ","
	p2 = strsearch(JSONstr,query2, p1 + strlen(query1))
	expt.exptsPerPoint = str2num(JSONstr[p1 + strlen(query1), p2-1])
	
	query1 = "pointsToAverage:"
	p1 = strsearch(JSONstr,query1, 0)
	query2 = ","
	p2 = strsearch(JSONstr,query2, p1 + strlen(query1))
	expt.pointsToAverage = str2num(JSONstr[p1 + strlen(query1), p2-1])
	
	String ExOps
	String ExOp
	query1 = "["
	p1 = strsearch(JSONstr,query1, 0)
	query2 = "]"
	p2 = strsearch(JSONstr,query2, p1 + strlen(query1))
	ExOps = JSONstr[p1 + strlen(query1), p2-1]
	Variable ExOpIdx
	Variable strPos = 0
	for (ExOpIdx = 0; ExOpIdx < expt.numExOps; ExOpIdx +=1)	
		query1 = "{"
		p1 = strsearch(ExOps,query1, strPos)
		query2 = "}"
		p2 = strsearch(ExOps,query2, p1 + strlen(query1))
		strPos = p2 
		ExOp = ExOps[p1 + strlen(query1), p2-1]
		
		query1 = "Name: "
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].name = ExOp[p1 + strlen(query1), p2-1]
			
		query1 = "Description: "
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].description = ExOp[p1 + strlen(query1), p2-1]
	
		query1 = "Device: "
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].device = ExOp[p1 + strlen(query1), p2-1]
			
		query1 = "ControlParameters: "
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].ControlParameters = ExOp[p1 + strlen(query1), p2-1]

		query1 = "Values:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].values = ExOp[p1 + strlen(query1), p2-1]
			
		query1 = "ScannableParameters:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].ScannableParameters = ExOp[p1 + strlen(query1), p2-1]
	
		query1 = "numScanParams:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].numScanParams = str2num( ExOp[p1 + strlen(query1), p2-1] )
			
		query1 = "MinVal:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].MinVal = ExOp[p1 + strlen(query1), p2-1]
		
		query1 = "MaxVal:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].MaxVal = ExOp[p1 + strlen(query1), p2-1]
		
		query1 = "MinInc:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].MinInc = ExOp[p1 + strlen(query1), p2-1]		
			
		query1 = "Scanned:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].Scanned = str2num( ExOp[p1 + strlen(query1), p2-1] )

		query1 = "ScanParameter:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].ScanParameter = str2num( ExOp[p1 + strlen(query1), p2-1] )

		query1 = "ScanStart:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].ScanStart = str2num( ExOp[p1 + strlen(query1), p2-1] )

		query1 = "ScanStop:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].ScanStop = str2num( ExOp[p1 + strlen(query1), p2-1] )

		query1 = "ScanInc:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].ScanInc = str2num( ExOp[p1 + strlen(query1), p2-1] )

		query1 = "Position:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].Position = str2num( ExOp[p1 + strlen(query1), p2-1] )

		query1 = "Shuttled:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].Shuttled = str2num( ExOp[p1 + strlen(query1), p2-1] )
	
		query1 = "SBCTotalTime:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].SBCTotalTime = str2num( ExOp[p1 + strlen(query1), p2-1] )
		
		query1 = "SBCPumpingTime:"
		p1 = strsearch(ExOp,query1, 0)
		query2 = ","
		p2 = strsearch(ExOp,query2, p1 + strlen(query1))
		expt.ExOps[ExOpIdx].SBCPumpingTime = str2num( ExOp[p1 + strlen(query1), p2-1] )
	endfor

end



function/S getTimeStamp()
	return Secs2Date(DateTime,-2)+"-"+ReplaceString(":",Secs2Time(DateTime,3), "")
end
