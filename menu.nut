/*
 * This file is part of TutorialAI, which is an AI for OpenTTD
 * Copyright (C) 2011  Leif Linse
 *
 * TutorialAI is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * TutorialAI is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with TutorialAI; If not, see <http://www.gnu.org/licenses/> or
 * write to the Free Software Foundation, Inc., 51 Franklin Street, 
 * Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

MENU_OPEN <- "__open__";
MENU_CLOSED <- "__closed__";


class Menu {

	sign_list = null;
	button_list = null;

	location = null;

	constructor() {
		this.sign_list = [];
		this.button_list = [];

		this.location = GSMap.GetTileIndex(GSMap.GetMapSizeX() / 2, GSMap.GetMapSizeY() / 2);
	}

	function Close();
	function SetLocation(top_tile); // Note: only affects new menus opened using Open.
	function Open(text, buttons);

	// Returns:
	// - "__open__" if open (see also MENU_OPEN constant above)
	// - "__closed__" if closed (see also MENU_CLOSED constant above)
	// - button-text if button "clicked"
	function CheckInput();

	// Polls CheckInput until it returns != MENU_OPEN and then returns the result
	// from CheckInput.
	function WaitUntilClose();

	static function SplitIntoLines(text, line_length)
	function GetWorkingMenuTop(num_lines);
}

function Menu::Close()
{
	foreach(sign in this.sign_list)
	{
		GSSign.RemoveSign(sign);
	}

	foreach(btn in this.button_list)
	{
		GSSign.RemoveSign(btn["sign"]);
	}

	this.sign_list = [];
	this.button_list = [];
}

/* static */ function Menu::ByteLen(str)
{
	local len = 0;
	foreach(c in str)
	{
		if(c <= 255)
			len += 1;
		else
			len += 4;
	}

	return len;
}

/* static */ function Menu::SplitIntoLines(text, line_length)
{

	//text = text.strip();

	local str_list = [];
	while(text.len() > line_length)
	{
		local next_line = "";
		local i = 0;
		while(i < text.len())
		{
			local curr_word_len = i;
			if(next_line.len() + 1 + curr_word_len > line_length)
			{
				// There is not enough room to add more words to new_line
				if(next_line.len() == 0)
				{
					// Detected a word longer than line_length
					// => force break the word

					local next_word = text.slice(0, line_length - 1);
					next_line = next_word + "-";
					text = text.slice(line_length - 1);
				}
				else
				{
					// next_line has been filled by one or more words
				}

				break;
			}

			// A word break has been found, and there is room for it (see checks above)
			if(text[i] == ' ' || 
					text[i] == '\n' || // or new-line
					i == text.len() - 1) // or last char
			{
				local next_word = text.slice(0, i);
				if(next_line.len() != 0)
					next_line += " ";
				next_line += next_word;

				local new_line = text[i] == '\n';

				// Remove word from text
				text = text.slice(i + 1); // correct? i or i + 1?

				if(new_line)
					break;

				// "restart" char-loop from first char
				i = 0;
				continue;
			}

			// Next char
			++i;
		} 

		str_list.append(next_line);
	}

	// Append last line
	if(text.len() > 0)
		str_list.append(text);


	// Fill upp with spaces at end of lines
	for(local i = 0; i < str_list.len(); ++i)
	{
		if(str_list[i].len() == 0) // don't fill up empty lines
			continue;

		while(str_list[i].len() < line_length)
		{
			str_list[i] += " ";
		}
	}

	return str_list;
}

function Menu::GetWorkingMenuTop(num_lines)
{
	local curr_loc_menu_capacity = Helper.Min(GSMap.GetMapSizeX() - GSMap.GetTileX(this.location), GSMap.GetMapSizeY() - GSMap.GetTileY(this.location));
	local menu_top = this.location;
	if(curr_loc_menu_capacity < num_lines)
	{
		local needed_cap = num_lines - curr_loc_menu_capacity;
		menu_top = Tile.GetTileRelative(menu_top, -needed_cap, -needed_cap);

		if(!GSMap.IsValidTile(menu_top))
		{
			if(Helper.Min(GSMap.GetMapSizeX(), GSMap.GetMapSizeY()) >= num_lines)
				menu_top = GSMap.GetTileIndex(0, 0); // Resort to 0,0 if moving menu upwards from current loc failed
			else
			{
				// Menu is too large for current map!!
				return null;
			}

		}
	}

	return menu_top;
}

function Menu::SetLocation(top_tile)
{
	if(!GSMap.IsValidTile(top_tile))
	{
		GSLog.Error("Bad tile sent to Menu::SetLocation");
		return false;
	}

	this.location = top_tile;
	return true;
}

function Menu::Open(text, buttons)
{
	this.Close();

	// Print menu-text into debug-screen
	local ai_debug_lines = Menu.SplitIntoLines(text, 80);
	GSLog.Info("");
	GSLog.Info("------------------------------------");
	foreach(line in ai_debug_lines)
	{
		GSLog.Info(line);
	}

	// Sign-based menu
	local sign_len = 30;
	local text_list = Menu.SplitIntoLines("(*) " + text, sign_len);
	local menu_top = this.GetWorkingMenuTop(text_list.len() + 1 + buttons.len());

	if(menu_top == null)
	{
		// Map is too small to display menu
		Helper.SetSign(this.location, "Menu Failed - Too small map!");
		GSLog.Info("The map was too small to display the following text as signs: ");
		foreach(text_str in text_list)
		{
			GSLog.Info("   " + text_str);
		}

		foreach(button in buttons)
		{
			GSLog.Info("   [" + button + "]");
		}
	}

	// Place text signs
	local curr_tile = menu_top;
	foreach(text_str in text_list)
	{
		if(text_str.len() > 0) // don't place empty signs
		{
			local sign = GSSign.BuildSign(curr_tile, text_str);
			this.sign_list.append(sign);
		}

		curr_tile = Tile.GetTileRelative(curr_tile, 1, 1);
	}

	// Place button signs
	curr_tile = Tile.GetTileRelative(curr_tile, 1, 1); // a gap-line between message and buttons
	GSLog.Info("");
	foreach(button in buttons)
	{
		local sign = GSSign.BuildSign(curr_tile, "[" + button + "]");
		local btn = {
			name = button,
			sign = sign
		}
		this.button_list.append(btn);

		curr_tile = Tile.GetTileRelative(curr_tile, 1, 1);


		// display buttons also in AI-debug window
		GSLog.Info("[" + button + "]");
	}

	
	if(buttons.len() > 0)
	{
		GSLog.Info("");
		GSLog.Info("(buttons can't be clicked in AI-debug window. You must remove the corresponding sign in the map to \"click\" it.");
	}

}

function Menu::CheckInput()
{
	if(this.sign_list.len() == 0)
		return MENU_CLOSED;

	local result = MENU_OPEN;
	foreach(btn in this.button_list)
	{
		if(!GSSign.IsValidSign(btn.sign))
		{
			// Button "clicked"
			result = btn.name;
			break;
		}
	}

	if(result != MENU_OPEN)
	{
		// Close menu.
		this.Close();
	}

	return result;
}

function Menu::WaitUntilClose()
{
	local ret = this.CheckInput();
	while(ret == MENU_OPEN)
	{
		GSController.Sleep(5);
		ret = this.CheckInput();
	}

	return ret;
}
