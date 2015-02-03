#pragma rtGlobals=3		// Use modern global access method.
#pragma version=1.17
#pragma IgorVersion=6.20

// **********************************
// Version 1.0 first release
//		This is the second beta release; it includes a change that is incompatible with the first. The parameters to
//		MakeListIntoWaveSelector() have been changed.
// Version 1.01
//		Fixed bug: MakeListIntoWaveSelector() set CDF to root:, but didn't restore user's CDF
//		Added reporting of double-click in notification proc
// Version 1.02
//		Fixed bug: List had extra rows below the rows containing wave names, etc.
//		Added extended notification proc: Added function parameters giving the name of the window containing the 
//			list, and the name of the list. If you need this information, see the isExtendedProc parameter of
//			WS_SetNotificationProc().
//		Previously, the Selection Changed notification was not passed along when a data folder was selected. Now,
//			all selection changes are passed to the notification procedure.
//		Added WS_CountSelectedObjects() function.
//		Added constants for notification event codes.
//		Added two new event codes: WMWS_FolderOpened and WMWS_FolderClosed
//		Fixed bug: double-click in space below the data (in blank space at bottom of list) was interpreted as a real
//			double-click.
// Version 1.03
//		Made notification function name storage compatible with triple names.
//		Added object name filter function.
//		Prevented certain harmful interactions with the debugger.
//		Hook function to update the widget didn't work with lists in sub-windows
//
// Version 1.04
//		Fixed a bug: in a datafolders-only list, if a datafolder was selected when WS_UpdateWaveSelectorWidget()
//			was called, the selected datafolder was opened even if it was closed before.
//
//	Version 1.05
//		Added WS_FindAndKillWaveSelector(windowname, listcontrolname)
//		Fixed bug: deleting a WaveSelectorWidget list control would cause bad things to happen!
//
// Version 1.06
//		Amended the documentation based on AG's helpful comments.
//
// Version 1.07
//		JP061222: Added sorting, MakePopupIntoWaveSelectorSort(), WS_SetGetSortOrder(), etc.
//		Changed WaveSelectorVersion to 1.07.
//
// Version 1.08
//		JW 070108: Added functions WS_AddSelectableString() and WS_RemoveSelectableString() to support things like
//		adding "_calculated_" to the Wave Selector.
//
//	Version 1.09
//		JW 070426: Now handles renaming of the host window using the Rename event in the window hook function.
//
//	Version 1.10
//		JW 071003: Fixed bug: The nameFilterProc was being called with just the name of a proposed object
//		instead of the full path. The documentation states that it is the full path.
//
//	Version 1.11
//		JW 080314: Added definitions for constants WMWS_SelectionNonContiguous and WMWS_SelectionContiguous so that
//		you don't have to use misspelled words! Retained the misspelled ones for backward compatibility.
//
//	Version 1.12
//		JW 080604: Fixed bug: When a WaveSelector widget was in an exterior panel (or its children) the hook function
//		was attached to the root window, instead of the exterior panel window. Consequently, the hook function didn't
//		get called, which meant that the data structures weren't cleaned up, and the contents weren't refreshed when
//		the window was activated.
//
//	Version 1.13
//		JW 090320: Added WS_SetGetFilterString
//
//	Version 1.14
//		JW 100208: Removed call to undocumented WinIsExterior function in favor of GetWindow exterior.
//
//	Version 1.15
//		JW 100329: Now checks for a recreation macro for the window containing the widget. If it exists, it does not kill
//		the data folder containing the data for the list.
//
//	Version 1.16
//		JW 100513: Changed required Igor version to 6.20 because of the rtGlobals = 3
//		KillDataFolder -> KillDataFolder/Z because multiple paths to killing the data folder could be activated if there are both a
//		popup wave selector and a plain wave selector in the same panel.
//	Version 1.17
// 		JW 100611: rtGlobals=3 turned up instances of out-of-range access to list wave when a click occurs in the space below the last real row.
// **********************************

// **********************************
//	Documentation
//
//	This procedure file provides functions to turn a listbox control in a control panel into a hierarchical wave
//	browser. This gives you the ability to make a control panel where you can select a wave from any datafolder.
//	This is a poor cousin of the WaveBrowser widget used in Igor's dialogs.
//
//	Actually, the WaveSelectorWidget procedure file allows you to choose to display  waves, numeric variables,
//	string variables, or just data folders. You cannot display a combination of waves, numeric variables and/or
//	string variables.
//
//	Selections are  made by clicking waves (or variables or strings). To select more than one wave, you can
//	hold down the shift key and drag over rows you wish to select. If you already have a wave selected, shift-
//	click to select everything between the existing selection and the click location. You can make non-continguous
//	selections by hold down the command key (Macintosh) or Cntrl key (Windows) and clicking. Cmd- or Cntrl-
//	clicking toggles the selected state of an item.
//
//	Actually, the forgoing paragraph doesn't take account of the selectionMode optional parameter, which
// 	can be used to prohibit multiple selections or discontiguous selections.
//
//	Unlike the WaveBrowser widget in Igor's dialogs, objects are de-selected when they are hidden. Even
//	worse, objects are de-selected when a folder is opened.
//
//	To use the WaveSelectorWidget, make a control panel with a bare-bones ListBox control, such as you get
//	if you use the command
//			ListBox listboxName,pos={left, top},size={width, height}
//	all by itself. This listbox is not useable as it has no listwave or selwave.
//
//	You then call  the function MakeListIntoWaveSelector(), which creates the necessary waves, sets up data
//	structures, attaches hook functions, etc., to make the listbox control into a hiearchical display of
//	data folders and (waves, variables, or strings) in your experiment.
//
//	Note that  this means you can't use a control panel recreation macro to build a control panel containing
//	a WaveSelectorWidget listbox. You must modify the recreation macro to simplify the ListBox command,
//	and you must add a call to MakeListIntoWaveSelector().
//
//	For an example of the use of WaveSelectorWidget, see Scatter Plot Matrix 2.ipf. You will find it in your
//	Igor Pro folder, in WaveMetrics Procedures:Graphing:.
//
//	There is a demo of the WaveSelectorWidget; pull down the File menu and 
//	select Examples->Programming->WaveSelectorWidgetExample.pxp
//
//	Function Reference
//
//	All the functions take two standard input parameters that identify the listbox control. These are:
//		windowname		string expression giving the name of the window (graph or control panel)
//							containing the listbox control.
//		listcontrolname		string expression giving the name of the listbox control.
//
//	The Functions
//
//	MakeListIntoWaveSelector(windowname, listcontrolname, [content, selectionMode, listoptions, matchStr, nameFilterProc])
//		content				optional parameter to select what is displayed in the list. A set of constants  
//							is provided for your convenience:							
//								WMWS_Waves			hierarchical display of waves in data folders
//								WMWS_NVars			hierarchical display of numeric variables 
//															in data folders
//								WMWS_Strings			hierarchical display of string variables in 
//															data folders
//								WMWS_DataFolders		hierarchical display of just the data folders
//							if absent, defaults to WMWS_Waves
//
//		selectionMode		optional parameter to set the selection mode. A set of constants is provided
//							for your convenience:
//								WMWS_SelectionNonContiguous
//														Allows multiple, non-contiguous selections.
//								WMWS_SelectionContiguous
//														Allows multiple selections, but they must 
//														be contiguous.
//								WMWS_SelectionSingle	Only a single item my be selected at a time.
//							WMWS_SelectionNonContiguous is the default.
//
//		listoptions			optional parameter containing a string to be passed as the options parameter to the
//							WaveList() function. See documentation of WaveList(). The string is limited to 200 characters.
//							If listoptions is not set, it  defaults to "".
//							Since it is passed to WaveList, it works only with a Wave Selector containing waves.
//
//		matchStr			optional parameter to select a subset of objects based on names and wildcards. See, for instance,
//							the WaveList() function for details.
//
//		nameFilterProc	optional parameter to name a function to filter objects before they are put into the list.
//							The function itself has the following format:
//
//								Function FilterProc(aName, contents)
//									String aName		// object name with full data folder path
//									Variable contents	// content code as described for the content parameter
//
//									return 0 to reject or 1 to accept
//								end
//
//							For example, to allow only objects starting with "w" (a trivial example that doesn't really
//							require a filter function):
//
//							Function MyFilter(aName, contents)
//								String aName
//								Variable contents
//								
//								String leafName = ParseFilePath(0, aName, ":", 1, 0)
//								if (CmpStr(leafName[0], "v") == 0)
//									return 1
//								endif
//								
//								return 0
//							end
//
//		Makes the specified listbox control into a WaveSelectorWidget. Setting content to WMWS_DataFolders
//		makes a listbox in which you can select data folders. Any other value of content does not include data folders
//		in the selection list, even though data folder rows can be selected.
//
//		To set the value of an optional parameter, you must use the name of the parameter. For instance, to
//		call MakeListIntoWaveSelector() to display numeric variables, call it like this:
//			MakeListIntoWaveSelector("MyWindow", "MyListbox", content=WMWS_NVars)
//
// WS_AddSelectableString(windowname, listcontrolname, theString)
//
//		Puts an arbitrary string into the row just above the root folder row. Allows you to put things like "_calculated_"
//		into a Wave Selector allowing a choice between XY and Waveform data. The same string can be added more than once.
//
//		theString				The string to add to the selector
//
// WS_RemoveSelectableString(windowname, listcontrolname, theString)
//
//		Removes a string added by WS_AddSelectableString.
//
//		theString				The string to be removed. Not case-sensitive; removes the first string that matches theString.
//								Note that if you have both "ABC" and "abc", in that order, "ABC" will be removed.
//								If no string matches, WS_RemoveSelectableString silently does nothing.
//
//	WS_IndexedObjectPath(windowname, listcontrolname, index)
//
//		Returns the full path of the index'th object in the list. If it is displaying something other than just data folders,
//		indexing skips data folders. That allows you to get the path to the first wave, second wave, etc.
//
//	WS_SelectedObjectsList(windowname, listcontrolname)
//
//		Returns a semicolon-separated list of selected items. Unless you created the widget with 
//		content set to WMWS_DataFolders, the returned list does not include data folders. 
//		Each list item is a complete path to the selected object.
//
//	WS_CountSelectedObjects(windowname, listcontrolname)
//
//		Returns a count of selected objects. Unless you created the widget with 
//		content set to WMWS_DataFolders, the returned count does not include data folders. 
//		May be faster than using WS_SelectedObjectsList() and then using ItemsInList() on the returned list.
//		If you will need the list, it is better to call WS_SelectedObjectsList() and then ItemsInList().
//
//	WS_SelectObjectList(windowname, listcontrolname, ObjectList)
//		ObjectList			string containing a semicolon-separated list of object names.
//
//		Selects the objects in the list. The object names must be full paths. Does *not* 
//		clear any pre-existing selections, so you can build up selections by calling this function repeatedly.
//
//	WS_SelectAnObject(windowname, listcontrolname, ObjectPath)
//		ObjectPath			string containing the full path name of a single object to be selected.
//
//		Adds a single object to the selections in the list. Does *not* clear any pre-existing selections, 
//		so you can build up selections by calling this function repeatedly. If you wish to select a single 
//		object, call WS_ClearSelection() first.
//
//	WS_ClearSelection(windowname, listcontrolname)
//
//		Programmatically de-selects any selected objects.
//
//	WS_UpdateWaveSelectorWidget(windowname, listcontrolname)
//
//		Should be rarely needed. Updates the list of objects by closing the root: folder, then opening any data
//		folders that were open before the root: data folder was closed. This function is used internally by
//		WaveSelectorWidget.ipf to update the contents whenever the window containing the list becomes the
//		active  window, in case user actions have changed the contents. You might need this function if your
//		control panel makes or kills objects.
//
//	WS_OpenAFolder(windowname, listcontrolname, FolderPathToOpen)
//		FolderPathToOpen	String containing the full path to a data folder to be opened.
//
//		Programmatically opens a data folder, displaying the contents of the folder. The path string may end
//		with a colon, but it is not required. If the folder's parent is not open, the folder will not be found
// 		and WS_OpenAFolder will fail.
//
// WS_OpenAFolderFully(windowname, listcontrolname, FolderPathToOpen)
//		FolderPathToOpen	String containing the full path to a data folder to be opened.
//
//		Programmatically opens a data folder, displaying the contents of the folder. The path string may end
//		with a colon, but it is not required. WS_OpenAFolderFully travels down the folder path, making sure
//		all the folders in the path are open. Slower than WS_OpenAFolder, but surer.
//
//	WS_CloseAFolder(windowname, listcontrolname, FolderPathToClose)
//		FolderPathToClose	String containing the full path to a data folder to be closed.
//
//		Programmatically closes a data folder, hiding the contents of the folder. The path string may end
//		with a colon, but it is not required.
//
//	WS_SetNotificationProc(windowname, listcontrolname, procname [, isExtendedProc])
//		procname			String containing the name of a funtion to be called when an item or items in
//							the list is selected.
//		isExtendedProc		Optional parameter. If not present, or if zero, use this format:
//
//								WS_NotificationProc(SelectedItem, EventCode)
//									String SelectedItem		// string with full path to the item clicked on in the wave selector
//									Variable EventCode		// the ListBox event code that triggered this notification
//									
//									.... function body ....
//								end
//
//							if isExtendedProc is non-zero, notification proc has this format:
//
//								WS_NotificationProc(SelectedItem, EventCode, OwningWindowName, ListboxControlName)
//									String SelectedItem			// string with full path to the item clicked on in the wave selector
//									Variable EventCode			// the ListBox event code that triggered this notification
//									String OwningWindowName	// String containing the name of the window containing the listbox
//									String ListboxControlName	// String containing the name of the listbox control
//									
//									.... function body ....
//								end						
//
//							Pass "" as procname to disable notification
//
//		Since only one item is passed to the notification proc, if you need a list of selected items you will have to use
//		WS_SelectedObjectsList() to get the list.
//
//		See the constants below for event codes.
//
//		NOTE: all the events have the potential to change the list of selected objects.
//
// WS_FindAndKillWaveSelector(windowname, listcontrolname)
// 		given the window and list control name, kills the list control, removes the selector widget from the list
//		of wave selectors in the window, and kills the data folder associated with the list control.
//
//	MakePopupIntoWaveSelectorSort(windowname, listcontrolname, popupcontrolname [,popupcontrolwindow])
//		listcontrolname	must already be a version 1.07 WaveSelectorWidget (#pragma version=1.07 or later)
//
//		popupcontrolname is the name of a simple popup with only the position and title needed:
//
//			PopupMenu sortKind, pos={275,20},title="Sort By"
//			MakePopupIntoWaveSelectorSort(windowname, listcontrolname, "sortKind")
//
//		MakePopupIntoWaveSelectorSort can be called up to 8 times for the same PopupMenu control,
//		allowing it to control the sorting of up to 8 lists in any window.
//		See the MakePopupIntoWaveSelectorSort() comments, below.
//
//	WS_SetGetSortOrder(windowname, listcontrolname, sortKindOrMinus1, sortReverseOrMinus1)
//		Sets or gets the sort ordering. sortKindOrMinus1 and sortReverseOrMinus1 are pass-by-reference
//		Listcontrolname can be the popupcontrolname passed to MakePopupIntoWaveSelectorSort.
//
//	WS_SetFilterString(windowname, listcontrolname, newFilterString)
//		Sets the match string. See MakeListIntoWaveSelector for information about the match string.
//		The previous filter string is the return value. 
//
//	WS_GetFilterString(windowname, listcontrolname)
//		Returns the current match string. See MakeListIntoWaveSelector for information about the match string.
//
// **********************************

// constants for content parameter to MakeListIntoWaveSelector()
Constant WMWS_Waves = 1
Constant WMWS_NVars = 2
Constant WMWS_Strings = 3
Constant WMWS_DataFolders = 4

// constants for selectionMode parameter
Constant WMWS_SelectionNonContinguous = 0
Constant WMWS_SelectionNonContiguous = 0
Constant WMWS_SelectionContinguous = 1
Constant WMWS_SelectionContiguous = 1
Constant WMWS_SelectionSingle = 2

// constants for notification events
Constant WMWS_FolderOpened = 1
Constant WMWS_FolderClosed = 2
Constant WMWS_DoubleClick = 3
Constant WMWS_SelectionChanged = 4
Constant WMWS_SelectionChangedShift = 5

// constants for WaveSelectorListInfo.sortKind and WS_SetGetSortOrder()
Constant WMWS_sortNone = 0			// default sort order, this will be Creation Order for waves
Constant WMWS_sortByName = 1
Constant WMWS_sortByCreationDate= 2
Constant WMWS_sortByModificationDate= 3
Constant WMWS_sortByNumberOfPoints= 4
Constant WMWS_sortByDimensionality= 5

// constants for error codes from MakeListIntoWaveSelector()
Constant WMWS_ErrorNoError = 0
Constant WMWS_ErrorOptionStringTooLong = 1

static Constant MAX_OBJ_NAME = 31
static Constant MAX_DOUBLE_NAME = 63		// 31 chars # 31 chars
static Constant WaveSelectorVersion = 1.07	// added sortKind and sortReverse
static Constant MAX_SORT_LIST_CONTROLS = 8	// maximum # of list controls that one sort PopupMenu will sort

// structure used to store information about the widget as user data in the listbox control
static Structure WaveSelectorListInfo
	int16	version
	int16	contents								// one of WMWS_Waves, WMWS_NVars, WMWS_Strings, or WMWS_DataFolders
	char	folderName[MAX_OBJ_NAME+1]		// last element of path starting with root:Packages:WM_WaveSelectorList:
	char	ListWaveName[MAX_OBJ_NAME+1]		// resides in folder named by folderName
	char	SelWaveName[MAX_OBJ_NAME+1]
	char	wavelistOptions1[100]
	char	wavelistOptions2[100]
	char	wavelistMatchStr[MAX_OBJ_NAME+1]
	char	nameFilterProcStr[3*MAX_OBJ_NAME+3]
	char	NotificationProc[3*MAX_OBJ_NAME+3]
	int16	isExtendedProc
	int16	sortKind		// WMWS_sortNone, etc. See OpenAFolder()
	int16	sortReverse		// boolean
	int32	RootFolderRow
EndStructure

Function MakeListIntoWaveSelector(windowname, listcontrolname, [content, selectionMode, listoptions, matchStr, nameFilterProc])
	String windowname
	String listcontrolname
	Variable content									// one of WMWS_Waves, WMWS_NVars, WMWS_Strings, or WMWS_DataFolders
	Variable selectionMode
	String listoptions								// a string to pass in the Options parameter of WaveList; overrides options
	String matchStr
	String nameFilterProc
	
	Variable err = WMWS_ErrorNoError
	
	if (ParamIsDefault(content))
		content = WMWS_Waves
	endif
	
	if (ParamIsDefault(selectionMode))
		selectionMode = WMWS_SelectionNonContiguous
	endif
	
	if (ParamIsDefault(listoptions))
		listoptions = ""
	endif
	
	if (ParamIsDefault(matchStr))
		matchStr = "*"
	endif
	
	if (ParamIsDefault(nameFilterProc))
		nameFilterProc = ""
	endif
	
	if (strlen(listoptions) > 200)
		listoptions = ""
		err = WMWS_ErrorOptionStringTooLong
	endif
	
	Variable selectMode = 10
	switch (selectionMode)
		case WMWS_SelectionNonContiguous:
			selectMode = 10
			break;
		case WMWS_SelectionContiguous:
			selectMode = 7
			break;
		case WMWS_SelectionSingle:
			selectMode = 6
			break;
	endswitch
	
	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	if (ListInfo.version != 0)
		KillDataFolder/Z $("root:Packages:WM_WaveSelectorList:"+ListInfo.folderName)
	endif

	ListInfo.version = WaveSelectorVersion
	ListInfo.contents = content
	ListInfo.NotificationProc = ""
	ListInfo.isExtendedProc = 0
	ListInfo.RootFolderRow = 0
	
	Variable optionsLen = strlen(listoptions)
	if (optionsLen > 100)
		ListInfo.wavelistOptions1 = listoptions[0,99]
		ListInfo.wavelistOptions2 = listoptions[100,optionsLen-1]
	else
		ListInfo.wavelistOptions1 = listoptions
		ListInfo.wavelistOptions2 = ""
	endif
	ListInfo.wavelistMatchStr = matchStr
	ListInfo.nameFilterProcStr = nameFilterProc
	
	ListBox $listcontrolname, win=$windowname, proc=WaveSelectorListProc,mode=selectMode
	ListBox $listcontrolname, win=$windowname, widths={20,500},keySelectCol=1,editStyle=1
	String SaveDF = GetDataFolder(1)
	SetDataFolder root:
	
	NewDataFolder/O/S Packages
	NewDataFolder/O/S WM_WaveSelectorList
	ListInfo.folderName = UniqueName("WaveSelectorInfo", 11, 0)
	NewDataFolder/O/S $ListInfo.folderName
	// one row, to be filled with the root object. Later, the root object will be opened and the opening code
	// will fill in the contents of the root object.
	Make/T/N=(1, 2, 2) ListWave		// second layer holds full path info
	Make/N=(1, 2) SelWave
	ListBox $listcontrolname, win=$windowname, listWave=ListWave, selWave=SelWave
	ListInfo.ListWaveName = "ListWave"
	ListInfo.SelWaveName = "SelWave"
	String infoStr
	StructPut/S ListInfo, infoStr
	ListBox $listcontrolname, win=$windowname, userData(WaveSelectorInfo)=infoStr
	String/G ListWindow = windowname;
	String/G ListCName = listcontrolname
	
	SetDataFolder SaveDF
	ListWave[0][1][0] = "root"
	ListWave[0][1][1] = "root"
	ListWave[0][0][1] = "root"
	SelWave[0][0] = 0x40					// it's a data folder, make it a disclosure control. The root folder starts out open, so it is in the open position.
	Variable index=0
	Variable listrow = 1
	String objname
	String indentString = "    "
	OpenAFolder(ListInfo, 0)				// open the root folder
	SelWave[0][0] = 0x50
	
	// get root window name
	String hostwindowname = WS_FindHookableHost(windowname)
	SetWindow $hostwindowname, hook(WaveSelectorWidgetHook) = WMWS_WinHook
	if (WinIsExterior(hostwindowname))
		// JW 100208 to get activation events for an exterior panel on both Windows and Macintosh, you have to hook both the
		// exterior panel window and the host window
		hostwindowname = RootWindowName(hostwindowname)
		SetWindow $hostwindowname, hook(WaveSelectorWidgetHook) = WMWS_WinHook
	endif

	return err
end

Function WS_AddSelectableString(windowname, listcontrolname, theString)
	String windowname
	String listcontrolname
	String theString
	
	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	if (ListInfo.version == 0)
		return -1
	endif
	
	Wave SelWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.SelWaveName)
	Wave/T ListWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.ListWaveName)
	
	InsertPoints ListInfo.RootFolderRow, 1, SelWave, ListWave
	Variable stringrow = ListInfo.RootFolderRow
	ListInfo.RootFolderRow += 1
	
	ListWave[stringrow][1] = theString
	
	StructPut/S ListInfo, userdata
	ListBox $listcontrolname, win=$windowname, userData(WaveSelectorInfo)=userdata
	
	return stringrow
end	

Function WS_RemoveSelectableString(windowname, listcontrolname, theString)
	String windowname
	String listcontrolname
	String theString
	
	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	if (ListInfo.version == 0)
		return -1
	endif
	
	Wave SelWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.SelWaveName)
	Wave/T ListWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.ListWaveName)
	
	Variable i
	for (i = 0; i < ListInfo.RootFolderRow; i += 1)
		if (CmpStr(ListWave[i][1], theString) == 0)
			DeletePoints i, 1, SelWave, ListWave
			ListInfo.RootFolderRow -= 1
			StructPut/S ListInfo, userdata
			ListBox $listcontrolname, win=$windowname, userData(WaveSelectorInfo)=userdata
			break;
		endif
	endfor
	
	return ListInfo.RootFolderRow
end

Function/S WS_IndexedObjectPath(windowname, listcontrolname, index)
	String windowname
	String listcontrolname
	Variable index

	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	if (ListInfo.version == 0)
		return ""
	endif
	
	Wave SelWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.SelWaveName)
	Wave/T ListWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.ListWaveName)
	
	Variable nrows = DimSize(ListWave, 0)
	if (index >= nrows)
		return ""
	endif
	Variable i, count=0
	if (ListInfo.contents != WMWS_DataFolders)
		for (i = 0; i < nrows; i += 1)
			if ((SelWave[i][0] & 0x40) == 0)		// skip disclosure triangle
				if (count == index)
					return ListWave[i][1][1]
				endif
				count += 1
			endif
		endfor
	else
		for (i = 0; i < nrows; i += 1)
			if (count == index)
				return ListWave[i][1][1]
			endif
			count += 1
		endfor
	endif
	
	return ""
end

Function/S WS_SelectedObjectsList(windowname, listcontrolname)
	String windowname
	String listcontrolname

	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	if (ListInfo.version == 0)
		return ""
	endif
	
	Wave SelWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.SelWaveName)
	Wave/T ListWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.ListWaveName)
	
	Variable nrows = DimSize(ListWave, 0)
	Variable i
	String theList = ""
	for (i = 0; i < nrows; i += 1)
		if ( (ListInfo.contents != WMWS_DataFolders) && (SelWave[i][0] & 0x40) )
			continue		// we don't want datafolders in the list unless this is a datafolder selection list
		endif
		
		if (SelWave[i][1] & 9)
			theList += ListWave[i][1][1] + ";"
		endif
	endfor
	
	return theList
end

Function WS_CountSelectedObjects(windowname, listcontrolname)
	String windowname
	String listcontrolname

	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	if (ListInfo.version == 0)
		return 0
	endif
	
	Wave SelWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.SelWaveName)
	Wave/T ListWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.ListWaveName)
	
	Variable nrows = DimSize(ListWave, 0)
	Variable i
	Variable theCount = 0
	for (i = 0; i < nrows; i += 1)
		if ( (ListInfo.contents != WMWS_DataFolders) && (SelWave[i][0] & 0x40) )
			continue		// we don't want datafolders in the list unless this is a datafolder selection list
		endif
		
		if (SelWave[i][1] & 9)
			theCount += 1
		endif
	endfor
	
	return theCount
end

Function WS_SelectObjectList(windowname, listcontrolname, ObjectList[, OpenFoldersAsNeeded])
	String windowname
	String listcontrolname
	String ObjectList
	Variable OpenFoldersAsNeeded

	if (ParamIsDefault(OpenFoldersAsNeeded))
		OpenFoldersAsNeeded = 0
	endif

	Variable nItems = ItemsInList(ObjectList)
	Variable i
	for (i = 0; i < nItems; i += 1)
		WS_SelectAnObject(windowname, listcontrolname, StringFromList(i, ObjectList), OpenFoldersAsNeeded = OpenFoldersAsNeeded)
	endfor
end

Function WS_SelectAnObject(windowname, listcontrolname, ObjectPath[, OpenFoldersAsNeeded])
	String windowname
	String listcontrolname
	String ObjectPath
	Variable OpenFoldersAsNeeded
	
	if (strlen(ObjectPath) == 0)
		return 0
	endif
	
	if (ParamIsDefault(OpenFoldersAsNeeded))
		OpenFoldersAsNeeded = 0
	endif

	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	if (ListInfo.version == 0)
		return -1
	endif
	
	if (OpenFoldersAsNeeded)
		String PathToFolder = ObjectPath
		PathToFolder = ParseFilePath(1,  ObjectPath, ":", 1, 0)
		WS_OpenAFolderFully(windowname, listcontrolname, PathToFolder)
	endif
	
	Wave SelWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.SelWaveName)
	Wave/T ListWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.ListWaveName)
	
	Variable nrows = DimSize(ListWave, 0)
	Variable i
	String theList = ""
	for (i = 0; i < nrows; i += 1)
		if ( (ListInfo.contents != WMWS_DataFolders) && (SelWave[i][0] & 0x40) )
			continue		// we don't want datafolders in the list unless this is a datafolder selection list
		endif
		
		if (CmpStr(ListWave[i][1][1], ObjectPath) == 0)
			SelWave[i][1] = SelWave[i][1] | 1
		endif
	endfor
	
	return 0
end

Function WS_ClearSelection(windowname, listcontrolname)
	String windowname
	String listcontrolname

	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	if (ListInfo.version == 0)
		return NaN
	endif
	
	Wave SelWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.SelWaveName)
	Wave/T ListWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.ListWaveName)

	SelWave[][1] = 0
end

Function WS_UpdateWaveSelectorWidget(windowname, listcontrolname)
	String windowname
	String listcontrolname

	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	if (ListInfo.version == 0)
		return -1
	endif
	
	Wave SelWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.SelWaveName)
	Wave/T ListWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.ListWaveName)
	
	Variable nrows = DimSize(ListWave, 0)
	Variable i, j
	String theList = ""
	
	// first make a list of open data folders so we can open them again later
	for (i = 0; i < nrows; i += 1)
		if ((SelWave[i][0] & 0x50) == 0x50)			// 0x40 means it's a checkbox row, which is a datafolder; 0x10 means it is checked, which means the data folder is open
			theList += ListWave[i][1][1] + ";"
		endif
	endfor
	
	String selectedWavesList = WS_SelectedObjectsList(windowname, listcontrolname)
	
	CloseAFolder(ListInfo, ListInfo.RootFolderRow)				// This will remove everything but added strings from the list
	
	Variable numFolders = ItemsInList(theList)
	if (numFolders > 0)
		for (i = 0; i < numFolders; i += 1)
			String folderPath = StringFromList(i, theList)
			Variable listrows = DimSize(ListWave, 0)
			for (j = 0; j < listrows; j += 1)
				if (CmpStr(ListWave[j][1][1], folderPath) == 0)
					OpenAFolder(ListInfo, j)
					SelWave[j][0] = 0x50
					break;
				endif
			endfor
		endfor
	endif
	
	WS_SelectObjectList(windowname, listcontrolname, selectedWavesList, OpenFoldersAsNeeded = 1)
end

Function WS_OpenAFolder(windowname, listcontrolname, FolderPathToOpen)
	String windowname
	String listcontrolname
	String FolderPathToOpen
	
	if (strlen(FolderPathToOpen) == 0)
		return 0
	endif
	
	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	if (ListInfo.version == 0)
		return -1
	endif
	
	Wave SelWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.SelWaveName)
	Wave/T ListWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.ListWaveName)
	
	Variable nrows = DimSize(ListWave, 0)
	Variable i
	Variable lastcharpos = StrLen(FolderPathToOpen)-1
	if (CmpStr(FolderPathToOpen[lastcharpos], ":") == 0)
		FolderPathToOpen = FolderPathToOpen[0, lastcharpos-1]
	endif
	
	for (i = 0; i < nrows; i += 1)
		if ((SelWave[i][0] & 0x40) == 0)		// is it a disclosure triangle?
			continue
		endif
		if (CmpStr(ListWave[i][1][1], FolderPathToOpen) == 0)
			if ( (SelWave[i][0] & 0x10)  == 0)
				OpenAFolder(ListInfo, i)
				SelWave[i][0] = 0x50			// check the checkbox
			endif
			break;
		endif
	endfor
	
	return 0
end

Function WS_OpenAFolderFully(windowname, listcontrolname, FolderPathToOpen)
	String windowname
	String listcontrolname
	String FolderPathToOpen
	
	if (strlen(FolderPathToOpen) == 0)
		return 0
	endif
	
	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	if (ListInfo.version == 0)
		return -1
	endif

	String FolderPath = ParseFilePath(0, FolderPathToOpen, ":", 0, 0)
	if (CmpStr(FolderPath, "root") != 0)
		return -1
	endif
	
	WS_OpenAFolder(windowname, listcontrolname, FolderPath)

	FolderPath += ":"
	Variable i = 1
	do
		String dfStr = ParseFilePath(0, FolderPathToOpen, ":", 0, i)
		i += 1
		if (strlen(dfStr) == 0)
			break;
		endif
		
		FolderPath += dfStr
		WS_OpenAFolder(windowname, listcontrolname, FolderPath)
		FolderPath += ":"
	while(1)
end

Function WS_CloseAFolder(windowname, listcontrolname, FolderPathToClose)
	String windowname
	String listcontrolname
	String FolderPathToClose
	
	if (strlen(FolderPathToClose) == 0)
		return 0
	endif
	
	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	if (ListInfo.version == 0)
		return -1
	endif
	
	Wave SelWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.SelWaveName)
	Wave/T ListWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.ListWaveName)
	
	Variable nrows = DimSize(ListWave, 0)
	Variable i
	Variable lastcharpos = StrLen(FolderPathToClose)-1
	if (CmpStr(FolderPathToClose[lastcharpos], ":") == 0)
		FolderPathToClose = FolderPathToClose[0, lastcharpos-1]
	endif
	
	for (i = 0; i < nrows; i += 1)
		if (CmpStr(ListWave[i][1][1], FolderPathToClose) == 0)
			CloseAFolder(ListInfo, i)
			SelWave[i][0] = 0x40			// un-check the checkbox
			break;
		endif
	endfor
	
	return 0
end

Function WS_SetNotificationProc(windowname, listcontrolname, procname [, isExtendedProc])
	String windowname
	String listcontrolname
	String procname
	Variable isExtendedProc
	
	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	if (ListInfo.version == 0)
		return -1
	endif
	
	ListInfo.NotificationProc = procname
	ListInfo.isExtendedProc = isExtendedProc

	StructPut/S ListInfo, userdata
	ListBox $listcontrolname, win=$windowname, userData(WaveSelectorInfo)=userdata
end

// private functions

Function namefiltertemplate(theNameWithPath, ListContents)
	String theNameWithPath
	Variable ListContents		// can't imagine why this would be necessary, but better to have it than to want it
	
	return 1
end

// JP061222: Version 1.07
static Function OpenAFolder(ListInfo, DataFolderRow)
	STRUCT WaveSelectorListInfo &ListInfo
	Variable DataFolderRow		// row number in list that contains the data folder to be opened
	
	Wave SelWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.SelWaveName)
	Wave/T ListWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.ListWaveName)
	String parentDF = ListWave[DataFolderRow][1][1]
	String parentDFwColon = parentDF+":"
	String saveDF = GetDataFolder(1)
	String objects = ""
	Variable nObjects = 0
	Variable i
	
	Variable nrows = 0
	Variable nRowsTooMany = 0		// variable to count how many waves are rejected
	if (ListInfo.contents != WMWS_DataFolders)
		SetDataFolder $(parentDFwColon)
		if (ListInfo.contents == WMWS_Waves)
			objects = WaveList(ListInfo.wavelistMatchStr, ";", ListInfo.wavelistOptions1+ListInfo.wavelistOptions2)
		elseif (ListInfo.contents == WMWS_NVars)
			objects = VariableList(ListInfo.wavelistMatchStr, ";", 4)+VariableList(ListInfo.wavelistMatchStr, ";", 5)
		elseif (ListInfo.contents == WMWS_Strings)
			objects = StringList(ListInfo.wavelistMatchStr, ";")
		endif
		nObjects = ItemsInList(objects)
		if (strlen(ListInfo.nameFilterProcStr) > 0)
			FUNCREF namefiltertemplate namefilterproc = $ListInfo.nameFilterProcStr
			String oldList = objects
			objects = ""
			Variable oldNObjects = nObjects
			nObjects = 0
			for (i = 0; i < oldNObjects; i += 1)
				String aName = StringFromList(i, oldList)
				if (namefilterproc(parentDFwColon+PossiblyQuoteName(aName), ListInfo.contents))
					objects += aName+";"
					nObjects += 1
				endif
			endfor
		endif
		// JP: Sort only approved objects
		if( nObjects )
			if( ListInfo.sortKind )
				if (ListInfo.contents == WMWS_Waves)
					switch( ListInfo.sortKind )
						case WMWS_sortByCreationDate:
						case WMWS_sortByModificationDate:
						case WMWS_sortByNumberOfPoints:
						case WMWS_sortByDimensionality:
							objects= WS_SortWaveList(objects, ListInfo.sortKind)
							break
					endswitch
				endif
				// all kinds of objects support sort by name and reverse
				if( ListInfo.sortKind == WMWS_sortByName )
					objects= SortList(objects, ";",16)	// Case insensitive alphanumeric sort that sorts wave0 and wave9 before wave10.
				endif
			endif
			if( ListInfo.sortReverse )
				objects= WS_ReverseList(objects)
			endif
		endif
		nrows += nObjects
		SetDatafolder saveDF
	endif
	nrows += CountObjects(parentDFwColon, 4)
	
	Variable listrow = DataFolderRow+1
	
	InsertPoints DataFolderRow+1, nrows, SelWave, ListWave
	Variable index=0
	String objname
	String indentString = "    " + returnIndentString(ListWave[DataFolderRow][1][0])
	SetDataFolder $(parentDFwColon)
	// waves
	if (ListInfo.contents != WMWS_DataFolders)
			for (i = 0; i < nObjects; i += 1)
				objname = StringFromList(i, objects)
				ListWave[listrow][0][1] = parentDF
				ListWave[listrow][1][1] = parentDFwColon+PossiblyQuoteName(objname)
				ListWave[listrow][1][0] = indentString+objname
				listrow += 1
			endfor
	endif
	if (nRowsTooMany)
		DeletePoints/M=0 listrow, nRowsTooMany, ListWave, SelWave
	endif
	index = 0
	// data folders
	do
		objname = GetIndexedObjName("", 4, index)
		if (strlen(objname) == 0)
			break
		endif
		ListWave[listrow][0][1] = parentDF
		ListWave[listrow][1][1] = parentDFwColon+PossiblyQuoteName(objname)
		ListWave[listrow][1][0] = indentString+objname
		SelWave[listrow][0] = 0x40
		index += 1
		listrow += 1
	while(1)
	SelWave[DataFolderRow][0] = SelWave[DataFolderRow][0] & ~1		// de-select the row just clicked
	SetDatafolder saveDF
end

Function CloseAFolder(ListInfo, DataFolderRow)
	STRUCT WaveSelectorListInfo &ListInfo
	Variable DataFolderRow		// row number in list that contains the data folder to be opened
	
	Wave SelWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.SelWaveName)
	Wave/T ListWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.ListWaveName)
	String parentDF = ListWave[DataFolderRow][1][1]

	Variable endrow = DimSize(ListWave, 0)
	Variable parentLen = StrLen(parentDF)
	
	Variable index	
	Variable listrow = DataFolderRow+1
	
	for (index = listrow; index < endrow; index += 1)
		if (CmpStr(parentDF, (ListWave[index][1][1])[0,parentLen-1]) != 0)
			break;
		endif
	endfor
	Variable npnts = index - listrow
	DeletePoints listrow, npnts, ListWave, SelWave
	SelWave[DataFolderRow][0] = SelWave[DataFolderRow][0] & ~1	// de-select the disclosure triangle cell just clicked
end

Function WMWS_WinHook(H_Struct)
	STRUCT WMWinHookStruct &H_Struct
	
	Variable statusCode = 0
	
	STRUCT WaveSelectorListInfo ListInfo
	
	StrSwitch(H_Struct.eventName)
		case "renamed":
			WS_HandleWindowRename(H_Struct)
			statusCode = 0
			break
		
		// JW 100513
		// a collection of event types where it is convenient to check to see if the controls still exist
		// previously, this code ran for every event type, including mousemoved!
		case "activate":
		case "deactivate":
		case "kill":
		case "resize":
		case "modified":
		case "enablemenu":
		case "subwindowKill":
		case "hide":
		case "show":
		case "showtools":
		case "hidetools":
		case "showinfo":
		case "hideinfo":
			String saveDF = GetDataFolder(1)
			SetDataFolder root:Packages:WM_WaveSelectorList
			
			Variable i
	
			for (i = CountObjects("", 4)-1; i >= 0; i -= 1)
				String folderName =  GetIndexedObjName("", 4, i)
				if (strlen(folderName) == 0)
					break;
				endif
				
				SetDataFolder folderName
				
				SVAR/Z ctrlName = ListCName
				SVAR/Z ControlWindowName = ListWindow
				
				if (SVAR_Exists(ctrlName) && SVAR_Exists(ControlWindowName))
				
					ControlInfo/W=$ControlWindowName $ctrlName
					if (V_flag == 0)
						// For some reason, the control has disappeard. Maybe a programmer is working on something and
						// deleted the control. This will kill the data folder associated with the list. It should have been killed by the list proc kill event,
						// but maybe things were in an uncompilable state at the time.
						WS_FindAndKillWaveSelector(ControlWindowName, ctrlName)
					else
						String userdata = GetUserData(ControlWindowName, ctrlName, "WaveSelectorInfo")
						ListInfo.version = 0
						StructGet/S ListInfo, userdata
						if (ListInfo.version == 0)
							continue
						endif
						
						strswitch (H_Struct.eventName)
							case "activate":							// activate
								WS_UpdateWaveSelectorWidget(ControlWindowName, ctrlName)
								break;
						endswitch
					endif
				else
					KillDataFolder/Z :				// Missing essential global variables- must be a relic of a discarded list.
				endif
				
				SetDataFolder root:Packages:WM_WaveSelectorList
			endfor
			SetDataFolder saveDF
		break
	EndSwitch
	
	
	return statusCode		// 0 if nothing done, else 1
End

// ParentWindow and ChildWindow are the names of a root window or a full path to a child window.
// This function returns non-zero if ParentWindow is the same window as ChildWindow or if
// ParentWindow contains ChildWindow. ParentWindow does not have to be a direct ancestor.
// ParentWindow       childWindow      returns
//   panel0               panel0         1
//   panel0               panel0#p0      1
//   panel0#p1            panel0#p1      1
//   panel1#p0            panel0#p0      0
//   panel0#p0            panel0#p0      1
//   panel0#p0            panel0#p0#p1   1
//   panel0#p0            panel0#p00     0
static Function IsWindowOrChild(ParentWindow, ChildWindow)
	String ParentWindow, ChildWindow
	
	if (stringmatch(ChildWindow, ParentWindow))
		return 1
	endif
	
	return stringmatch(ChildWindow, ParentWindow+"#*")
end

static Function/S RootWindowName(winpath)
	String winpath
	
	Variable poundPos = strSearch(winpath, "#", 0)
	if (poundPos < 0)
		return winpath
	endif
	
	return winpath[0, poundPos-1]
end

static Function WS_HandleWindowRename(s)
	STRUCT WMWinHookStruct &s

	String saveDF = GetDatafolder(1)
	SetDataFolder root:Packages:WM_WaveSelectorList
	
	String oldWinName = s.oldWinName
	Variable oldWinNameLen = strlen(oldWinName)
	
	// a string with a list of WaveSelectorWidgets in the window and its sub-windows used to be kept
	// in order to make it easier to find the right control in a hook function. But that is now obsolete.
	// Remove it here in case this is a panel that was created by an older version of WaveSelectorWidget.
	if (strlen(GetUserData(s.winName, "", "WaveWidgetList")) != 0)
		SetWindow $(s.winname), userData(WaveWidgetList)=""
	endif
	
	Variable i
	do
		String fName = GetIndexedObjName("", 4, i)
		if (strlen(fName) == 0)
			break;
		endif
		
		SetDatafolder fName
		
		SVAR/Z ListWindow
		if (SVAR_Exists(ListWindow))
			if (IsWindowOrChild(oldWinName, ListWindow))
				ListWindow = s.winName+ListWindow[oldWinNameLen, strlen(ListWindow)-1]
			endif
		endif
		
		SetDataFolder root:Packages:WM_WaveSelectorList
		
		i += 1
	while (1)
	
	SetDataFolder saveDF
end

Function WS_ExtNotificationTemplate(SelectedItem, EventCode, WindowName, ListboxName)
	String SelectedItem
	Variable EventCode
	String WindowName
	String ListboxName
	
end

Function WS_NotificationTemplate(SelectedItem, EventCode)
	String SelectedItem
	Variable EventCode
	
end

Static Function CallNotificationProc(object, event, windowName, listName, procName, isExtended)
	String object
	Variable event
	String windowName, listName
	String procName
	Variable isExtended
	
	if (isExtended)
		FUNCREF WS_ExtNotificationTemplate notifyFunc = $(procName)
		notifyFunc(object, event, windowName, listName)
	else
		FUNCREF WS_NotificationTemplate extNotifyFunc = $(procName)
		extNotifyFunc(object, event)
	endif
end

Function WS_KillListDataFolder(rootWindow, containerWindow, folderName)
	String rootWindow, containerWindow, folderName

	// if a recreation macro exists, don't kill the data folder containing the list waves!
	if (Exists("ProcGlobal#"+rootWindow) == 5)
		return 0
	endif
	
	KillDataFolder/Z $("root:Packages:WM_WaveSelectorList:"+folderName)
end

Function WaveSelectorListProc(LB_Struct) : ListboxControl
	STRUCT WMListboxAction &LB_Struct
	
	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(LB_Struct.win, LB_Struct.ctrlName, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	if (ListInfo.version == 0)
		return 0
	endif
	
	Wave SelWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.SelWaveName)
	Wave/T ListWave = $("root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName+":"+ListInfo.ListWaveName)
	
	Variable index=0
	switch(LB_Struct.eventCode)
		case -1:		// control being killed
			String cmd = GetIndependentModuleName()+"#WS_KillListDataFolder(\""
			cmd += StringFromList(0, LB_Struct.win, "#")
			cmd += "\",\""
			cmd += LB_Struct.win
			cmd += "\",\""
			cmd += ListInfo.FolderName
			cmd += "\")"
			Execute/P/Q cmd
			break;
		case 1:			// mouse down
			if (LB_Struct.col == 0)
				// if a click in the list results in breaking into the debugger, the debugger fakes a mouse-up with bogus information.
				// This widget doesn't put a header in the list, but if it did, we could get a mouse-down in row -1
				if ( (LB_Struct.row < 0) || (LB_Struct.row >= DimSize(SelWave, 0)) )
					break;		// click in row beyond any data (blank space at bottom of list box)
				endif

				if (SelWave[LB_Struct.row][0] & 0x40)
					SelWave[LB_Struct.row][0] = SelWave[LB_Struct.row][0] & ~1
				endif
			endif
			break;
		case 2:			// mouse up
			if (LB_Struct.col == 0)
				// if a click in the list results in breaking into the debugger, the debugger fakes a mouse-up with bogus information.
				// That is the only way I have found to get a row of -1 here.
				if ( (LB_Struct.row < 0) || (LB_Struct.row >= DimSize(SelWave, 0)) )
					break;		// click in row beyond any data (blank space at bottom of list box)
				endif

				if (SelWave[LB_Struct.row][0] & 0x40)
					if (SelWave[LB_Struct.row][0] & 0x10)	// if it's checked, it needs to be opened
						OpenAFolder(ListInfo, LB_Struct.row)
						if (ListInfo.NotificationProc[0] != 0)
							CallNotificationProc(ListWave[LB_Struct.row][1][1], WMWS_FolderOpened, LB_Struct.win, LB_Struct.ctrlName, ListInfo.NotificationProc, ListInfo.isExtendedProc)
						endif
					else
						CloseAFolder(ListInfo, LB_Struct.row)
						if (ListInfo.NotificationProc[0] != 0)
							CallNotificationProc(ListWave[LB_Struct.row][1][1], WMWS_FolderClosed, LB_Struct.win, LB_Struct.ctrlName, ListInfo.NotificationProc, ListInfo.isExtendedProc)
						endif
					endif
					DoUpdate
				endif
			endif
			break;
		case 3:			// double-click
				// if a click in the list results in breaking into the debugger, the debugger fakes a mouse-up with bogus information.
				// This widget doesn't put a header in the list, but if it did, we could get a mouse-down in row -1
			if ( (LB_Struct.row < 0) || (LB_Struct.row >= DimSize(SelWave, 0)) )
				break;		// click in row beyond any data (blank space at bottom of list box)
			endif
			
			if (LB_Struct.col == 1)
				if ( (SelWave[LB_Struct.row][0] & 0x50) == 0x50 )
					CloseAFolder(ListInfo, LB_Struct.row)
					SelWave[LB_Struct.row][0] = 0x40
					SelWave[LB_Struct.row][1] = 0
				elseif ( (SelWave[LB_Struct.row][0] & 0x50) == 0x40 )
					OpenAFolder(ListInfo, LB_Struct.row)
					SelWave[LB_Struct.row][0] = 0x50
					SelWave[LB_Struct.row][1] = 0
				else		// not a container row: report a double-click
					if (ListInfo.NotificationProc[0] != 0)
						CallNotificationProc(ListWave[LB_Struct.row][1][1], LB_Struct.eventCode, LB_Struct.win, LB_Struct.ctrlName, ListInfo.NotificationProc, ListInfo.isExtendedProc)
					endif
				endif
			endif
			break;
		case 4:			// selection changed
		case 5:			// shift-selection
			if ( (LB_Struct.row < 0) || (LB_Struct.row >= DimSize(SelWave, 0)) )
				break;				// clicked row is outside the range of rows in the list (most likely in the space below the last real row)
			endif
			if (LB_Struct.col == 1)
				if (ListInfo.NotificationProc[0] != 0)
					CallNotificationProc(ListWave[LB_Struct.row][1][1], LB_Struct.eventCode, LB_Struct.win, LB_Struct.ctrlName, ListInfo.NotificationProc, ListInfo.isExtendedProc)
				endif
			endif
			break;
	endswitch
end

static Function/S returnIndentString(text)
	String text
	
	String returnStr
	
	Variable space = char2num(" ")
	Variable i=0
	Variable len = StrLen(text)
	for (i = 0; i < len; i += 1)
		if (char2num(text[i]) != space)
			break;
		endif	
	endfor
	
	returnStr = PadString("", i, space)
	return returnStr
end

//static Function GetIndexedWaveListFromUD(index, rootWindowName, outWindowName, outListName)
//	Variable index
//	String rootWindowName, &outWindowName, &outListName
//	
//	String thelist = GetUserData(rootWindowName, "", "WaveWidgetList")
//	if (index >= ItemsInList(thelist))
//		return -1
//	endif
//	outWindowName = StringByKey("WindowName", stringfromlist(index, thelist), "=", ",")
//	outListName = StringByKey("ListName", stringfromlist(index, thelist), "=", ",")
//	
//	return index
//end

Function WS_FindAndKillWaveSelector(windowname, listcontrolname)
	String windowname
	String listcontrolname

	Variable i

	String saveDF = GetDatafolder(1)
	SetDataFolder root:Packages:WM_WaveSelectorList

	for (i = CountObjects("", 4)-1; i >= 0; i -= 1)
		String fName = GetIndexedObjName("", 4, i)
		if (strlen(fName) == 0)
			break;
		endif
		
		SetDatafolder fName
		SVAR/Z ctrlName = ListCName
		SVAR/Z ListWindowName = ListWindow
		
		if (SVAR_Exists(ctrlName) && SVAR_Exists(ListWindowName))	
			if (CmpStr(ListWindowName, windowname) == 0)
				if (CmpStr(listcontrolname, ctrlName) == 0)
					ControlInfo/W=$ListWindowName $listcontrolname
					if (V_flag == 11)
						KillControl/W=$ListWindowName $listcontrolname
					endif
					if (CmpStr(saveDF, GetDataFolder(1)) == 0)
						saveDF = ParseFilePath(1, saveDF, ":", 1, 0)
					endif
					KillDataFolder/Z :
				endif
			endif
		endif
	
		SetDataFolder root:Packages:WM_WaveSelectorList
	endfor
	
	SetDataFolder saveDF
end

static Function/S FindFolderForWaveSelector(windowname, listcontrolname)
	String windowname
	String listcontrolname
	
	String theDFName = ""

	ControlInfo/W=$windowname $listcontrolname
	if (V_flag == 0)
		// control doesn't exist for some reason- search the folders for it
		String saveDF = GetDataFolder(2)
		SetDataFolder root:Packages:WM_WaveSelectorList
		
		Variable i = 0
		do
			String DFName = GetIndexedObjName("root:Packages:WM_WaveSelectorList", 4, i)
			if (strlen(DFName) == 0)
				break;
			endif
			
			SetDataFolder DFName
			
			SVAR/Z ListWindow
			SVAR/Z ListCName

			if (SVAR_Exists(ListWindow) && SVAR_Exists(ListCName))
				if ( (CmpStr(ListWindow, windowname) == 0) && (CmpStr(ListWindow, windowname) == 0) )
					theDFName = "root:Packages:WM_WaveSelectorList:"+DFName
					break;
				endif
			endif
			
			SetDataFolder ::
			
			i += 1
		while(1)
		
		SetDataFolder saveDF
	else
		// control exists- use the user data stored in the control
		STRUCT WaveSelectorListInfo ListInfo
		String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
		ListInfo.version = 0
		StructGet/S ListInfo, userdata
		if (ListInfo.version == 0)
			theDFName = ""			// list exists, but doesn't have the right user data- it must not be a wave selector
		else
			theDFName = "root:Packages:WM_WaveSelectorList:"+ListInfo.FolderName
		endif
	endif
	
	return theDFName
end

// Added Version 1.07 routines start here

static Structure ControlSpec
	char	windowname[MAX_DOUBLE_NAME+1]		// window for listcontrolname0
	char	controlname[MAX_OBJ_NAME+1]
EndStructure

// structure used to identify the listbox control(s) being sorted.
// It is stored as userData in the PopupMenu.
// At most 8 lists can be controlled by one sort popup menu.
static Structure WaveSelectorSortInfo
	int16	version
	
	int16  sortKind, sortReverse		// last values set
	STRUCT ControlSpec popupControl

	STRUCT ControlSpec listControls[MAX_SORT_LIST_CONTROLS]
EndStructure

// MakePopupIntoWaveSelectorSort can be called up to 8 times for the same PopupMenu control,
//	allowing it to control the sorting of up to 8 lists in any window.
//
// Each list must already be a WaveSelector.
//
// Each list's sorting order will be controlled by the one PopupMenu.
// For example:
//		MakePopupIntoWaveSelectorSort("Panel0", "list0InPanel0", "sortPopupInPanel0")
//		MakePopupIntoWaveSelectorSort("Panel0", "list1InPanel0", "sortPopupInPanel0")
//		MakePopupIntoWaveSelectorSort("Panel0", "list2InPanel0", "sortPopupInPanel0")
// makes the sortPopupInPanel0 control the sorting of three lists.
//
// Note that the popup and list controls in the above code are all in the Panel0 window.
//
// You can put the popup and list controls in completely different windows/subwindows like this:
//		MakePopupIntoWaveSelectorSort("Panel0#P0", "list0InPanel0P0", "sortPopupInPanel0", popupcontrolwindow= "Panel0")
//		MakePopupIntoWaveSelectorSort("Panel0#P1", "list0InPanel0P1", "sortPopupInPanel0", popupcontrolwindow= "Panel0")
//		MakePopupIntoWaveSelectorSort("Panel0#P2", "list0InPanel0P2", "sortPopupInPanel0", popupcontrolwindow= "Panel0")
// 
Function MakePopupIntoWaveSelectorSort(windowname, listcontrolname, popupcontrolname [,popupcontrolwindow])
	String windowname, listcontrolname, popupcontrolname, popupcontrolwindow

	if (ParamIsDefault(popupcontrolwindow))
		popupcontrolwindow= windowname
	endif

	STRUCT WaveSelectorSortInfo SortInfo
	String userdata = GetUserData(popupcontrolwindow, popupcontrolname, "WaveSelectorSortInfo")
	Variable firstTime= strlen(userdata) == 0
	if( !firstTime )
		StructGet/S SortInfo, userdata
	else
		SortInfo.version= WaveSelectorVersion
		SortInfo.popupControl.windowname= popupcontrolwindow
		SortInfo.popupControl.controlname= popupcontrolname
	endif

	// Remember which list control(s) the popup is sorting
	WS_AddListToBeSorted(SortInfo, windowname, listcontrolname)

	StructPut/S SortInfo, userdata
	PopupMenu $popupcontrolname, win=$popupcontrolwindow, userData(WaveSelectorSortInfo)=userdata
	if( firstTime )
		PopupMenu $popupcontrolname,win=$popupcontrolwindow,proc=WS_SortKindPopMenuProc, mode=0
		// we presume that all the lists controlled by the sort popup are set the same,
		// so the popup menu shows only the first list's sort order
		String cmd="PopupMenu "+popupcontrolname+", win="+popupcontrolwindow+",value=#\""+GetIndependentModuleName()+"#WS_SortKindMenu(\\\""+windowname+"\\\", \\\""+listcontrolname+"\\\")\""
		Execute cmd
	endif
End

Function WS_AddListToBeSorted(SortInfo, windowname, listcontrolname)
	STRUCT WaveSelectorSortInfo &SortInfo
	String windowname, listcontrolname

	// find the first blank controlname
	Variable i
	for(i= 0; i < MAX_SORT_LIST_CONTROLS; i+=1 )
		if( strlen(SortInfo.listControls[i].controlName) == 0 )
			SortInfo.listControls[i].windowname= windowname
			SortInfo.listControls[i].controlName= listcontrolname
			return 1
		endif
	endfor

	return 0
End


Function/S WS_SortKindMenu(windowname, listcontrolname)
	String windowname, listcontrolname
	
	Variable sortKind=-1, sortReverse=-1	// -1 means get
	
	WS_SetGetSortOrder(windowname, listcontrolname, sortKind, sortReverse)
	
	String menuList= "Name;Creation Order;Creation Date;Modification Date;Number of Points;Dimensionality;\\M1-;"	// unchecked
	Variable item=0
	switch( sortKind )
		case WMWS_sortByName:
			item= 1
			break
		case WMWS_sortNone:
			item= 2
			break
		case WMWS_sortByCreationDate:
			item= 3
			break
		case WMWS_sortByModificationDate:
			item= 4
			break
		case WMWS_sortByNumberOfPoints:
			item= 5
			break
		case WMWS_sortByDimensionality:
			item= 6
			break
	endswitch
	if( item )
		String checkMark= "\\M1!"+ num2char(18)
		String itemStr= StringFromList(item-1, menuList)+";"
		menuList= ReplaceString(itemStr, menuList, checkMark+itemStr, 0, 1)
	endif
	if( sortReverse )
		menuList += "\\M1!"+ num2char(18)
	endif
	menuList += "Reverse;"

	return menuList
End


Function WS_SortKindPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			WS_SortKindAction(pa.win,pa.ctrlName,pa.popNum)
			break
	endswitch

	return 0
End

static Function WS_SortKindAction(popupcontrolwindow,ctrlName,popNum)
	String popupcontrolwindow,ctrlName
	Variable popNum

	STRUCT WaveSelectorSortInfo SortInfo
	String userdata = GetUserData(popupcontrolwindow, ctrlName, "WaveSelectorSortInfo")
	StructGet/S SortInfo, userdata
	
	// we assume that each list has the same sorting values
	// largely because this routine always sets them to the same values
	Variable sortKind=-1, sortReverse=-1	// -1 means get
	WS_SetGetSortOrder(SortInfo.listControls[0].windowname, SortInfo.listControls[0].controlName, sortKind, sortReverse)

	switch( popNum )	// 1-based
		case 1:	// Name
			sortKind=  WMWS_sortByName
			break
		case 2:	// Creation Order
			sortKind=  WMWS_sortNone
			break
		case 3:	// Creation Date
			sortKind=  WMWS_sortByCreationDate
			break
		case 4:	// Modification Date
			sortKind=  WMWS_sortByModificationDate
			break
		case 5:	// Number of Points
			sortKind=  WMWS_sortByNumberOfPoints
			break
		case 6:	// Dimensionality
			sortKind=  WMWS_sortByDimensionality
			break
		case 8:	// Reverse
			sortReverse=  !sortReverse
			break
	endswitch

	WS_SetPopupSorting(popupcontrolwindow, ctrlName, sortKind, sortReverse)
End

static Function WS_SetPopupSorting(popupcontrolwindow, popupcontrolname, sortKind, sortReverse)
	String popupcontrolwindow, popupcontrolname
	Variable sortKind, sortReverse
	
	STRUCT WaveSelectorSortInfo SortInfo
	String userdata = GetUserData(popupcontrolwindow, popupcontrolname, "WaveSelectorSortInfo")
	StructGet/S SortInfo, userdata

	// remember the last values for WS_SetGetSortOrder
	SortInfo.sortKind= sortKind
	SortInfo.sortReverse= sortReverse
	StructPut/S SortInfo, userdata
	PopupMenu $popupcontrolname, win=$popupcontrolwindow, userData(WaveSelectorSortInfo)=userdata
	
	Variable i
	for(i= 0; i < MAX_SORT_LIST_CONTROLS; i+=1 )
		if( strlen(SortInfo.listControls[i].controlName) == 0 )
			break
		endif
		WS_SetGetSortOrder(SortInfo.listControls[i].windowname, SortInfo.listControls[i].controlName, sortKind, sortReverse)
		WS_UpdateWaveSelectorWidget(SortInfo.listControls[i].windowname, SortInfo.listControls[i].controlName)
	endfor

End


static Function/S WS_ReverseList(list)
	String list	// ";" separator
	
	String reversed=""
	Variable i, n=ItemsInList(list)
	for(i=n-1; i>= 0;i-=1)
		reversed += StringFromList(i,list)+";"
	endfor

	return reversed
End

static Function/S WS_SortWaveList(list, sortKind)
	String list	// ";" separator, full paths or names in the current data folder
	Variable sortKind

	Variable i, n=ItemsInList(list)

	String SaveDF = GetDataFolder(1)
	SetDataFolder root:
	NewDataFolder/O/S Packages
	NewDataFolder/O/S WM_WaveSelectorList
	Make/O/N=(n) index=p
	Make/O/D/N=(n) sortValue
	SetDataFolder SaveDF
	
	for(i=0; i<n; i+=1 )
		Variable sv= n	// sort to end
		String wn= StringFromList(i,list)
		Wave/Z w= $wn
		if( WaveExists(w) )
			switch(sortKind)
				case WMWS_sortByCreationDate:
					sv= CreationDate(w)
					break
				case WMWS_sortByModificationDate:
					sv= ModDate(w)
					break
				case WMWS_sortByNumberOfPoints:
					sv= numpnts(w)
					break
				case WMWS_sortByDimensionality:
					sv= 0
					Variable dim=0
					for(dim=0; dim<4; dim+=1)
						if( DimSize(w,dim) )
							sv= dim+1
						endif
					endfor
					break
			endswitch
		endif
		sortValue[i]= sv
	endfor
	Sort sortValue, index
	String sorted=""
	for(i=0; i<n; i+=1 )
		sorted += StringFromList(index[i],list)+";"
	endfor

	return sorted
End

Function WS_SetGetSortOrder(windowname, listcontrolname, sortKindOrMinus1, sortReverseOrMinus1)
	String windowname, listcontrolname	// windowname, listcontrolname can also be popupcontrolwindow, popupcontrolname passed into MakePopupIntoWaveSelectorSort
	Variable &sortKindOrMinus1		// -1 means don't change sortKind AND return the current sortKind
	Variable &sortReverseOrMinus1	// -1 means don't change sortReverse AND return the current sortReverse
	
	// are we setting/getting from the popup menu control or/a list control?
	ControlInfo/W=$windowName $listcontrolName
	if( V_Flag == 0 )
		return -1
	endif
	
	Variable isList= V_flag == 11
	
	String userdata
	Variable updateWidget= sortKindOrMinus1 != -1 || sortReverseOrMinus1 != -1

	if( isList )
		STRUCT WaveSelectorListInfo ListInfo
		userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
		StructGet/S ListInfo, userdata

		if( sortKindOrMinus1 == -1 )
			sortKindOrMinus1= ListInfo.sortKind
		else
			ListInfo.sortKind = sortKindOrMinus1
		endif
		
		if( sortReverseOrMinus1 == -1 )
			sortReverseOrMinus1= ListInfo.sortReverse
		else
			ListInfo.sortReverse = sortReverseOrMinus1
		endif
		
		StructPut/S ListInfo, userdata
		ListBox $listcontrolname, win=$windowname, userData(WaveSelectorInfo)=userdata
	
		if( updateWidget )
			WS_UpdateWaveSelectorWidget(windowname, listcontrolname)
		endif
	else
		String popupcontrolname= listcontrolname
		STRUCT WaveSelectorSortInfo SortInfo
		userdata = GetUserData(windowname, popupcontrolname, "WaveSelectorSortInfo")
		StructGet/S SortInfo, userdata


		if( sortKindOrMinus1 == -1 )
			sortKindOrMinus1= SortInfo.sortKind
		else
			SortInfo.sortKind = sortKindOrMinus1
		endif
		
		if( sortReverseOrMinus1 == -1 )
			sortReverseOrMinus1= SortInfo.sortReverse
		else
			SortInfo.sortReverse = sortReverseOrMinus1
		endif

		if( updateWidget )
			// updates the sorting of ALL controlled lists
			WS_SetPopupSorting(windowname, popupcontrolname, SortInfo.sortKind, SortInfo.sortReverse)
		endif
	endif
	
	return 0
End	

Function/S WS_SetFilterString(windowname, listcontrolname, newFilterString)
	String windowname, listcontrolname
	String newFilterString

	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata
	
	String oldFilterString = 	ListInfo.wavelistMatchStr
	
	if (CmpStr(newFilterString, oldFilterString) != 0)
		ListInfo.wavelistMatchStr = newFilterString
		StructPut/S ListInfo, userdata
		ListBox $listcontrolname, win=$windowname, userData(WaveSelectorInfo)=userdata
		WS_UpdateWaveSelectorWidget(windowname, listcontrolname)
	endif
end

Function/S WS_GetFilterString(windowname, listcontrolname)
	String windowname, listcontrolname

	STRUCT WaveSelectorListInfo ListInfo
	String userdata = GetUserData(windowname, listcontrolname, "WaveSelectorInfo")
	StructGet/S ListInfo, userdata

	return ListInfo.wavelistMatchStr
end

static Function WS_isRootWindow(WindowPath)
	String WindowPath
	
	return strsearch(WindowPath, "#", 0) < 0
end

static Function WinIsExterior(winPath)
	String winPath
	
	GetWindow/Z $winPath, exterior
	return V_value						// no need to check V_flag for error, this will be zero in case of an error (most likely error is a non-existent window)
end

static Function/S WS_FindHookableHost(WindowPath)
	String WindowPath
	
	if (WS_isRootWindow(WindowPath))
		return WindowPath
	endif
	
	Variable numLevels = ItemsInList(WindowPath, "#")
	Variable i
	String hostPath = WindowPath
	
	for (i = 0; i < numLevels; i += 1)
		if (WS_isRootWindow(hostPath))
			return hostPath
		endif
		if (WinIsExterior(hostPath))
			return hostPath
		endif
		
		Variable poundPos = strsearch(hostPath, "#", strlen(hostPath), 1)
		hostPath = hostPath[0, poundPos - 1]
	endfor
	
	return hostPath
end