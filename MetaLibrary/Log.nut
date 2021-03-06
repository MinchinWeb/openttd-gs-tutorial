﻿/*	Logging Interface v.3, r.221, [2012-01-28]
*		part of MinchinWeb's MetaLibrary v.4,
 *		originally part of WmDOT v.5
 *	Copyright © 2011-12 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */

/* Add this you the  Info.nut  file of your AI:

	function GetSettings() {
		AddSetting({name = "Debug_Level", description = "Debug Level ", min_value = 0, max_value = 7, easy_value = 3, medium_value = 3, hard_value = 3, custom_value = 3, flags = CONFIG_INGAME});
	}

 */


 class _MinchinWeb_Log_ {
	function GetVersion()       { return 3; }
	function GetRevision()		{ return 221; }
	function GetDate()          { return "2012-01-28"; }
	function GetName()          { return "Logging Interface"; }
 
	_DebugLevel = null;
	//	How much is output to the AIDebug Screen
	//	0 - run silently
	//	1 - Operations Noted here
	//	2 - 'normal' debugging - each step
	//	3 - substep
	//	4 - most verbose (including arrays)
	//	5 - including signs (generally nothing more to the debug screen)
	//	  - library (basic)
	//	6 - library (verbose)
	//  7 - library (signs)
	//
	//	Every level beyond 1 is indented 5 spaces per higher level
	 
	constructor()
	{
//		this._DebugLevel = 1;
//		_MinchinWeb_Log_.UpdateDebugLevel();
	
//		this.Settings = this.Settings(this);
	}
};

/*
class _MinchinWeb_Log_.Settings {

	_main = null;
	
	function _set(idx, val)
	{
		switch (idx) {
			case "DebugLevel":			this._main._DebugLevel = val; break;
			default: throw("the index '" + idx + "' does not exist");
		}
		return val;
	}
		
	function _get(idx)
	{
		switch (idx) {
			case "DebugLevel":			return this._main._DebugLevel; break;
			default: throw("the index '" + idx + "' does not exist");
		}
	}
	
	constructor(main)
	{
		this._main = main;
	}
 };
 */
 

  
function _MinchinWeb_Log_::Note(Message, Level=3) {
//	Displays the message if the Debug level is set high enough
	if (Level <=  _MinchinWeb_Log_.UpdateDebugLevel() ) {
		local i = 1;
		while (i < Level) {
			Message = "     " + Message;
			Level--;
		}
		GSLog.Info(Message);
	}
 }
 
 function _MinchinWeb_Log_::Warning(Message) {
	GSLog.Warning(Message);
 }
 
 function _MinchinWeb_Log_::Error(Message) {
	GSLog.Error(Message);
 }
 
function _MinchinWeb_Log_::Sign(Tile, Message, Level = 5)
{
	if (Level <= _MinchinWeb_Log_.UpdateDebugLevel() ) {
		GSSign.BuildSign(Tile, Message);
	}
}
 
function _MinchinWeb_Log_::PrintDebugLevel() {
	GSLog.Info("OpLog is running at level " + this._DebugLevel + ".");
 }
 
function _MinchinWeb_Log_::UpdateDebugLevel() {
//	Looks for an AI setting for Debug Level, and set the debug level to that
	local DebugLevel = 3;
	if (GSController.GetSetting("Debug_Level") != -1) {
		DebugLevel = GSController.GetSetting("Debug_Level");
	}
	return DebugLevel;
}