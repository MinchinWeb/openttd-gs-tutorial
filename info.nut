
class TestGame extends GSInfo {
	function GetAuthor()		{ return "Zuu"; }
	function GetName()			{ return "Game Tutorial"; }
	function GetDescription() 	{ return "Select this as game script and start a new game"; }
	function GetVersion()		{ return 1; }
	function GetDate()			{ return "2011-12-05"; }
	function CreateInstance()	{ return "TestGame"; }
	function GetShortName()		{ return "TUT_"; }
	function GetAPIVersion()	{ return "1.2"; }
	function GetUrl()			{ return ""; }

	function GetSettings() {
		AddSetting({name = "log_level", description = "Debug: Log level (higher = print more)", easy_value = 3, medium_value = 3, hard_value = 3, custom_value = 3, flags = CONFIG_INGAME, min_value = 1, max_value = 3});
		AddSetting({name = "debug_signs", description = "Debug: Build signs", easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, flags = CONFIG_BOOLEAN | CONFIG_INGAME});
	}
}

RegisterGS(TestGame());
