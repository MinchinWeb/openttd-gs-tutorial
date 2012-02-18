/*
 * License: GPL2
 */

SELF_VERSION <- 7;
require("version_upgrade.nut");

class TestGame extends GSInfo {
	function GetAuthor()           { return "Zuu"; }
	function GetName()             { return "Beginner Tutorial"; }
	function GetDescription()      { return "Don't use this script in your games, instead load the Beginner Tutorial scenario. The reason why you see this script is that you have the developer tools active."; }
	function GetVersion()          { return SELF_VERSION; }
	function GetDate()             { return "2001-02-18"; }
	function CreateInstance()      { return "TestGame"; }
	function GetShortName()        { return "TUT_"; }
	function GetAPIVersion()       { return "1.2"; }
	function GetUrl()              { return "http://www.tt-forums.net/viewtopic.php?f=65&t=57624"; }

	function MinVersionToLoad()    { return ALLOW_UPGRADE? 1 : SELF_VERSION; } // don't load save games saved with an older version of the GS. Instead let the old GS load that game.
	function IsDeveloperOnly()     { return true; } 

	function GetSettings() {
		AddSetting({name = "log_level", description = "Debug: Log level (higher = print more)", easy_value = 3, medium_value = 3, hard_value = 3, custom_value = 3, flags = CONFIG_INGAME, min_value = 1, max_value = 3});
		AddSetting({name = "debug_signs", description = "Debug: Build signs", easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, flags = CONFIG_BOOLEAN | CONFIG_INGAME});
	}
}

RegisterGS(TestGame());
