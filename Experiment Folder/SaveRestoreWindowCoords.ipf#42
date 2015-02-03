#pragma rtGlobals=1		// Use modern global access method.
#pragma IgorVersion= 6.0	// Has fixed GetWindow/MoveWindow on PCs, has GetWindow wsizeRM
#pragma version=6.1		// Shipped with Igor 6.1
//
// SaveRestoreWindowCoords.ipf - Window Coordinates Save/Restore Utilities, based on window name.
// 
// Version 1.01 5/02/2002, fixes for problem of panels on windows moving downwards with some Igors.
// Version 6.1 3/4/2009, limiting the Igor to 6.0 means we no longer need to deal with broken GetWindow/MoveWindow issues.
//						Added WC_WindowCoordinatesNamedHook().
//						Also, using wsizeRM handles maximized windows better.


//	WC_WindowCoordinatesHook
//
// Usage: SetWindow yourWindowName hook=WC_WindowCoordinatesHook
//
// or call WC_WindowCoordinatesSave() from your own window hook during the kill event
//
Function WC_WindowCoordinatesHook(infoStr)
	String infoStr

	Variable statusCode= 0
	String event= StringByKey("EVENT",infoStr)
	if( CmpStr(event,"kill") == 0 )
		String windowName= StringByKey("WINDOW",infoStr)
		WC_WindowCoordinatesSave(windowName)
	endif

	return statusCode
End

//	WC_WindowCoordinatesNamedHook
//
// Usage: SetWindow yourWindowName hook(someName)=WC_WindowCoordinatesNamedHook
//
// or call WC_WindowCoordinatesSave() from your own window hook during the kill event
//
Function WC_WindowCoordinatesNamedHook(hs)
	STRUCT WMWinHookStruct &hs

	Variable statusCode= 0
	strswitch(hs.eventName)
		case "kill":
			WC_WindowCoordinatesSave(hs.winName)
			break
	endswitch

	return statusCode
End

//
//	WC_WindowCoordinatesRestore
//
//	If coordinates for the named window have been saved,
//	the window is moved and sized accordingly, and 1 is returned.
//
//	If no coordinates are found, 0 is returned.
//
Function WC_WindowCoordinatesRestore(windowName)
	String windowName		// The named window must exist

	Variable restored= 0
	Variable vLeft, vTop, vRight, vBottom
	if( WC_WindowCoordinatesGetNums(windowName, vLeft,vTop, vRight, vBottom) )
		MoveWindow/W=$windowName vLeft, vTop, vRight, vBottom
		restored= 1
	endif
	return restored
End


#if Exists("PanelResolution") != 3
Static Function PanelResolution(wName)			// For compatibility with Igor 7
	String wName
	return 72
End
#endif


// WC_WindowCoordinatesSprintf
//
// %s in fmt is replaced with left,top,right,bottom
//
// Examples:
//
// String fmt="Display/W=(%s) as \"the title\""
// Execute WC_WindowCoordinatesSprintf("eventualGraphName",fmt,x0,y0,x1,y1,0)	// points
//
//
// String fmt="NewPanel/W=(%s)"
// Execute WC_WindowCoordinatesSprintf("eventualPanelName",fmt,x0,y0,x1,y1,1)	// pixels
//
Function/S WC_WindowCoordinatesSprintf(windowName,fmt,defLeft,defTop,defRight,defBottom,wantPixels)
	String windowName,fmt
	Variable defLeft,defTop,defRight,defBottom,wantPixels
	
	if( wantPixels && PanelResolution("") != 72 )
		wantPixels= 0
	endif

	if( wantPixels ) // convert from pixels to points
		defLeft /= ScreenResolution/72
		defTop /= ScreenResolution/72
		defRight /= ScreenResolution/72
		defBottom /= ScreenResolution/72
	endif
	WC_WindowCoordinatesGetNums(windowName, defLeft,defTop,defRight,defBottom)
	if( wantPixels ) // convert from saved points to pixels
		defLeft *= ScreenResolution/72
		defTop *= ScreenResolution/72
		defRight *= ScreenResolution/72
		defBottom *= ScreenResolution/72
	endif

	String coordinates
	sprintf coordinates, "%g, %g, %g, %g",defLeft,defTop,defRight,defBottom
	String result
	Sprintf result, fmt, coordinates	// %s in fmt is replaced with left,top,right,bottom
	return result
end

//
//	WC_WindowCoordinatesSave
//
Function WC_WindowCoordinatesSave(windowName)
	String windowName
	
	if( strlen(windowName) == 0 )
		windowName= WinName(0,255)
	endif
	DoWindow $windowName
	if( V_Flag == 0 )
		return 0
	endif
	// wsizeRM is useful on the PC, because a maximized window's restored size is returned instead of the maximized size.
	GetWindow $windowName, wsizeRM
	WC_WindowCoordinatesSetNums(windowName, V_left, V_top, V_right, V_bottom)
	return 1
End

//
//	WC_WindowCoordinatesSetNums
//
// Window coordinates are saved in a 5-column text wave
// as windowname,num2istr(left),num2istr(top),num2istr(right),num2istr(bottom),num2istr(topOffset)
//
// Saves coordinates for the named window, possibly adding a row to contain the window's coordinates.
// Returns the row of the named window.
//
Function WC_WindowCoordinatesSetNums(windowName, vLeft, vTop, vRight, vBottom)
	String windowName
	Variable vLeft, vTop, vRight, vBottom	// coordinates in points

	Variable row
	String dfSav= WC_SetDF()
	if( exists("W_windowCoordinates") != 1 )
		Make/O/T/N=(0,5) W_windowCoordinates
		WAVE/T coords= $WC_DF_Var("W_windowCoordinates")
		row= -1	// add new row
	else
		// search for matching row
		WAVE/T coords= $WC_DF_Var("W_windowCoordinates")
		if( DimSize(coords,1) != 5 )
			Redimension/N=(-1,5) coords	// in case we're updating a 1.01 version of the wave
		endif
		row= WC_WindowCoordinatesRow(coords,windowName)
	endif
	if( row == -1 )
		InsertPoints/M=0 0,1,coords
		row= 0
	endif
	coords[row][0]=windowName
	coords[row][1]=num2str(vLeft)
	coords[row][2]=num2str(vTop)	// GetWindow top in points
	coords[row][3]=num2str(vRight)
	coords[row][4]=num2str(vBottom)
	SetDataFolder dfSav
	return row
End


Function WC_WindowCoordinatesRow(coords,windowName)
	Wave/T coords
	String windowName
	
	Variable rows = DimSize(coords,0)
	Variable row= -1
	if( rows > 0 )
		do
			row += 1
			if( CmpStr(windowName,coords[row][0]) == 0 )
				return row
			endif
		while( row < rows-1 )
		row= -1	// not found
	endif
	return row
end

//
//	WC_WindowCoordinatesGetNums
//
//	If coordinates for the named window were found,
//		stores the coordinates into the vXXX variables, and 1 is returned.
//	If not found,
//		the vXXX variables are unchanged, and 0 is returned.
//
Function WC_WindowCoordinatesGetNums(windowName, vLeft, vTop, vRight, vBottom)
	String windowName
	Variable &vLeft, &vTop, &vRight, &vBottom	// outputs, pass by reference, not by value
	
	if( strlen(windowName) == 0 )
		return 0
	endif
	WAVE/T/Z coords= $WC_DF_Var("W_windowCoordinates")
	if( WaveExists(coords) == 0 )
		return 0
	endif
	Variable row= WC_WindowCoordinatesRow(coords,windowName)
	if( row < 0 )
		return 0
	endif
	vLeft= str2num(coords[row][1])	// changes value in calling routine !
	vTop= str2num(coords[row][2])	// GetWindow top in points
	vRight= str2num(coords[row][3])
	vBottom= str2num(coords[row][4])
	return 1
End


// WC_WindowCoordinatesGetStr returns "" or the coordinates separated by commas
// prints window coordinates into the returned string.
//
// See also: WC_WindowCoordinatesSprintf()
//
Function/S WC_WindowCoordinatesGetStr(windowName,usePixels)
	String windowName
	Variable usePixels	// set to 0 for points (normal), non-zero for pixels (panels)

	String coordinates= ""
	Variable vLeft, vTop, vRight, vBottom
	if( WC_WindowCoordinatesGetNums(windowName, vLeft, vTop, vRight, vBottom) )
		if( usePixels ) // convert from saved points to pixels
			vLeft *= ScreenResolution/72
			vTop *= ScreenResolution/72
			vRight *= ScreenResolution/72
			vBottom *= ScreenResolution/72
		endif
		sprintf coordinates, "%g, %g, %g, %g", vLeft, vTop, vRight, vBottom
	endif
	return coordinates
End

Function/S WC_DF()
	return "root:Packages:WindowCoordinates"
End

Function/S WC_SetDF()
	String oldDF= GetDataFolder(1)
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S $WC_DF()
	return oldDF
End

Function/S WC_DF_Var(varName)
	String varName
	return WC_DF()+":"+varName
End