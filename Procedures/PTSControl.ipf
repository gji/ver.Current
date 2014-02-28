#pragma rtGlobals=1		// Use modern global access method and strict wave access.

//	GPIBAddress =  "GPIB0::16::INSTR"
Function setPTS(GPIBAddress, PTSamplitude, PTSfrequency)
	String GPIBAddress
	Variable PTSamplitude
	Variable PTSfrequency
	Variable defaultRM, instr
	String resourceName = GPIBAddress
	String str
	
	viOpenDefaultRM(defaultRM)
	Variable status = viOpen(defaultRM, resourceName, 0, 0, instr)
	
	sprintf str, "F%d\nA%d\n", PTSfrequency, PTSamplitude
	VISAWrite instr, str
	
	Print getVISAErrors(instr, status)
	Print status
		
	viClose(instr)
	viClose(defaultRM)
End

Function getVISAErrors(instr, status)
	Variable instr	// An instrument referenced obtained from viOpen.
	Variable &status	// Output: Status code from VISA library or -1.

	Variable err = 0

	Variable v1
	VISARead instr, v1	// Sets V_flag and V_status.
	
	// Check for VISA library error
	err = GetRTError(1)	// Clear runtime error so Igor will not abort
	if (err != 0)	// VISARead failed?
		status = V_status
		return err	// Let calling routine deal with error if any.
	endif

	status = VI_SUCCESS
	return 0	// 0 indicates success.
End

Function writeToPTS(instr)
	Variable instr	// An instrument referenced obtained from viOpen

	// Transmits the contents of variable v1, the sine of .5 radians and the contents of
	// point 0 of wave1, separated by tabs with a carriage return and linefeed at the end.
	Variable PTSamplitude = 1
	Variable PTSfrequency = 1900000000
	String str
	sprintf str, "F%d\nA%d\n", PTSfrequency, PTSamplitude
	VISAWrite instr, str
End

Function FindGPIBDevices()
	Variable defaultRM=0, findList=0, retcnt
	String expr, instrDesc
	Variable i, status=0
	
	do		// Just a structure to break out of in case of error
		expr = "GPIB?*INSTR"			// Match all serial instruments.
		status = viOpenDefaultRM(defaultRM)
		if (status < 0)
			break
		endif
	
		status = viFindRsrc(defaultRM, expr, findList, retcnt, instrDesc)
		if (status < 0)
			break
		endif
		if (retcnt <= 0)
			break
		endif
	
		i = 1
		do
			Printf "Instrument %d: %s\r", i, instrDesc
	
			i += 1
			if (i > retcnt)
				break
			endif
	
			status = viFindNext(findList, instrDesc)
			if (status < 0)
				break
			endif
		while(1)
	while(0)
	
	if (status < 0)
		String errorDesc
		Variable viObject
	
		viObject = findList
		if (viObject == 0)
			viObject = defaultRM
		endif
	
		viStatusDesc(viObject, status, errorDesc)
		Printf "VISA Error: %s\r", errorDesc
	endif
	
	if (findList != 0)
		viClose(findList)
	endif
	if (defaultRM != 0)
		viClose(defaultRM)
	endif

	return status
End