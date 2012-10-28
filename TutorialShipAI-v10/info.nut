/*
 * This file is part of TutorialShipAI, which is an AI for OpenTTD
 * Copyright (C) 2012  Leif Linse & William Minchin
 *
 * TutorialShipAI is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * TutorialShipAI is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with TutorialShipAI; If not, see <http://www.gnu.org/licenses/> or
 * write to the Free Software Foundation, Inc., 51 Franklin Street, 
 * Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

SELF_VERSION <- 10;

class MainClass extends AIInfo {
	function GetAuthor()      { return "Zuu"; }
	function GetName()        { return "TutorialShipAI"; }
	function GetShortName()   { return "TSHP"; }
	function GetDescription() { return "Tutorial Ship AI"; }
	function GetAPIVersion()  { return "1.2"; }
	function GetVersion()     { return SELF_VERSION; }
	function MinVersionToLoad() { return 1; }
	function GetDate()        { return "2012-10-28"; }
	function GetUrl()         { return ""; }
	function UseAsRandomAI()  { return false; }
	function CreateInstance() { return "MainClass"; }
	function IsDeveloperOnly() { return true; }

	function GetSettings() {
		AddSetting({name = "log_level", description = "Debug: Log level (higher = print more)", easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1, flags = AICONFIG_INGAME, min_value = 1, max_value = 3});
	}
}

/* Tell the core we are an AI */
RegisterAI(MainClass());

