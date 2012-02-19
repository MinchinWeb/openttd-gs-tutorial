/* Include Tutorial files */
require("menu.nut");
require("tutorial_step.nut");
require("common.nut");
require("chapter_intro.nut");
require("chapter_navigation.nut");
require("chapter_airplanes.nut");
require("chapter_ships.nut");
require("chapter_trucks.nut");
require("chapter_buses.nut");
require("chapter_trains.nut");

/* Import SuperLib for GameScript */
import("util.superlib", "SuperLib", 21);
Result <- SuperLib.Result;
Log <- SuperLib.Log;
Helper <- SuperLib.Helper;
ScoreList <- SuperLib.ScoreList;
Tile <- SuperLib.Tile;
Direction <- SuperLib.Direction;
Town <- SuperLib.Town;
Industry <- SuperLib.Industry;

/* Import TileLabels */
import("scenario.tilelabels", "TileLabels", 1);

/* Globals */
g_menu <- null;
g_tile_labels <- null;
HUMAN_COMPANY <- 0;
CHAPTER_LIST <- [ ChapterIntro, ChapterNavigation, ChapterAirplanes, ChapterShips, ChapterTrucks, ChapterBuses, ChapterTrains ];
//CHAPTER_LIST <- [ "intro", "airplanes", "ships", "road vehicles", "trains" ];


class TestGame extends GSController 
{
	_current_chapter_id = null;
	_chapter_steps = null;
	_current_step = null;
	_first_step = false;

	_chapter_storage = null;

	_load_data = null;

	_end_of_tutorial = false;

	constructor()
	{
	}
}

/*
 * -------- Tutorial Engine --------------------------
 */
function TestGame::Start()
{
	// Any GameScript init code goes here
	local error_string = this.Init();
	if(error_string != null)
	{
		this.Sleep(1); // start game
		while(true)
		{
			// Broadcast error message from time to time so multiplayer error get noticed even if it is a
			// dedicated server.
			if(GSGame.IsMultiplayer() || !GSWindow.IsOpen(GSWindow.WC_GOAL_QUESTION, 1000))
				GSGoal.Question(1000, GSCompany.COMPANY_INVALID, error_string, GSGoal.QT_ERROR, GSGoal.BUTTON_CLOSE);

			this.Sleep(100);
		}
	}

	Log.Info("Tutorial setup done", Log.LVL_INFO);

	// Wait for the game to start
	this.Sleep(1);

	// Only when the game has started, the human company exist
	//local company_mode = GSCompanyMode(HUMAN_COMPANY);

	Log.Info("Tutorial starts now", Log.LVL_INFO);

	while (!this._end_of_tutorial) {
		this.HandleEvents();
		this.RunTutorial();
		this.Sleep(10);
	}

	// Keep alive after tutorial have ended to not show a crash message to the user
	while(true)
	{
		this.HandleEvents();
		this.Sleep(10);
	}
}

function TestGame::Init()
{
	local error = this.CheckGame();
	if(error != null) return error;

	g_menu = Menu();
	this._end_of_tutorial = false;

	// Initialize the tile labels library
	g_tile_labels = TileLabels("$L=");
	if (this._load_data != null && this._load_data.rawin("tile_labels"))
	{
		g_tile_labels.ImportFromSave(this._load_data.tile_labels);
	}
	g_tile_labels.ReadFromMap();

	this.InitBeforeNewChapter();

	local loaded_state = false;
	if (this._load_data != null)
	{
		// Try to load the chapter that was active when the game was saved
		local index = this.GetChapterIndex(this._load_data.chapter);
		if (index != -1 && LoadChapter(CHAPTER_LIST[index], this._load_data.chapter_storage))
		{
			// Set current step to the step that was just executed before when the game was saved
			this._current_step = Helper.Max(-1, this._load_data.step - 1);

			loaded_state = true;
		}
	}

	if(!loaded_state)
	{
		// No tutorial state was loaded from save (or loading failed)
		// => Start from the beginning (in future: possible show a menu of chapters)
		this.LoadChapter(CHAPTER_LIST[0]);
	}

	return null;
}

function TestGame::CheckGame()
{
	// Check for multiplayer game
	if(GSGame.IsMultiplayer())
	{
		this.Sleep(1); // start game

		// Report problem
		Log.Error("Error: Tutorial can't be run in multiplayer");
		return GSText(GSText.STR_ERROR_MULTIPLAYER);
	}

	// If GSOrders doesn't exist, OpenTTD is too old
	try
	{
		// dummy code that will throw an exception if GSOrder doesn't exist
		if(GSOrder.GetOrderCount) {}
	}
	catch(e)
	{
		return GSText(GSText.STR_ERROR_OLD_OPENTTD);
	}

	return null;
}

function TestGame::InitBeforeNewChapter(chapter_storage = {})
{
	this._chapter_steps = [];
	this._current_step = -1;
	this._chapter_storage = chapter_storage; // Table which all chapter steps can access to store data
}
function TestGame::AddStep( new_step )
{
	this._chapter_steps.append(new_step);
	new_step.SetStorageTable(this._chapter_storage);
}

function TestGame::HandleEvents()
{
	if(GSEventController.IsEventWaiting())
	{
		local ev = GSEventController.GetNextEvent();

		if(ev == null)
			return;

		// Make sure there is an active chapter step
		if(this._current_step < 0 || this._current_step >= this._chapter_steps.len())
			return;

		// Forward event to current chapter step
		this._chapter_steps[this._current_step].Event(ev);
	}
}

function TestGame::RunTutorial()
{
	// Is chapter done?
	if(this._current_step >= this._chapter_steps.len())
	{
		local next = this.GetNextChapter(this._current_chapter_id);
		if(next != null)
		{
			this.LoadChapter(next);
		}
		else
		{
			GSGoal.Question(0, HUMAN_COMPANY, GSText(GSText.STR_NO_MORE_CHAPTERS), GSGoal.QT_INFORMATION GSGoal.BUTTON_CLOSE);
			this._end_of_tutorial = true;
			return;
		}
	}

	// Is current step done?
	if(this._first_step || this._chapter_steps[this._current_step].IsDone())
	{
		this._current_step++;

		// reached end of tutorial?
		if(this._current_step >= this._chapter_steps.len())
			return;

		// Execute next step
		this._chapter_steps[this._current_step].Execute();

		// Remove flag that allows execution of non-finished steps if they are the first to be executed
		// (used both for first step in a chapter and after loading a save game)
		this._first_step = false;
	}
}

function TestGame::Save()
{
	Log.Info("Saving data to savegame", Log.LVL_INFO);
	return { 
		chapter = this._current_chapter_id,
  		step = this._current_step,
		chapter_storage = this._chapter_storage,
		tile_labels = g_tile_labels.ExportToSave()
	};

}

function TestGame::Load(version, tbl)
{
	Log.Info("Loading data from savegame of tutorial version: " + version, Log.LVL_INFO);
	Log.Info("chapter: " + tbl.chapter, Log.LVL_INFO);
	Log.Info("step: " + tbl.step, Log.LVL_INFO);

	// Store a copy of the table from the save game
	this._load_data = {}
   	foreach(key, val in tbl)
	{
		this._load_data.rawset(key, val);
	}	
}

/*
 * -------- Chapters ---------------------------------
 */
function TestGame::LoadChapter(chapter, chapter_storage = {})
{
	// Unload old chapter
	this.InitBeforeNewChapter(chapter_storage);

	if(chapter == null) return false;

	// Load new chapter
	this._current_chapter_id = chapter.ID();
	chapter.LoadChapter(this);

	// Set flag that first step is to be executed ( => there is no previous step that has to be marked as done )
	this._first_step = true;

	return true;
}

function TestGame::GetChapterIndex(chapter_id)
{
	for(local i = 0; i < CHAPTER_LIST.len(); i++)
	{
		if(chapter_id == CHAPTER_LIST[i].ID())
		{
			return i;
		}
	}

	return -1;
}

function TestGame::GetNextChapter(chapter_id)
{
	local chapter_index = null;

	local button = this.ModalQuestion(GSText(GSText.STR_NEXT_CHAPTER_OR_SELECT), GSGoal.BUTTON_YES + GSGoal.BUTTON_NO);
	if(button == GSGoal.BUTTON_YES)
	{
		// Display chapter menu
		local i = 0;
		while(chapter_index == null)
		{
			// Pick buttons
			local buttons = GSGoal.BUTTON_PREVIOUS + GSGoal.BUTTON_START + GSGoal.BUTTON_NEXT;

			// Display message for chapter i
			button = this.ModalQuestion(GSText(GSText.STR_CHAPTER_MENU_INTRO + i), buttons);

			switch(button)
			{
				case GSGoal.BUTTON_PREVIOUS:
					if(i > 0)
						i--;
					else
						i = CHAPTER_LIST.len() -1; // loop around
					break;

				case GSGoal.BUTTON_NEXT:
					if(i < CHAPTER_LIST.len() - 1)
						i++;
					else
						i = 0; // loop around
					break;

				case GSGoal.BUTTON_START:
					chapter_index = i;
					break;
			}
		}

	}
	else
	{
		// Use chapter + 1 as next chapter
		chapter_index = TestGame.GetChapterIndex(chapter_id) + 1;
	}
	
	if(chapter_index < 0) return null;
	if(chapter_index >= CHAPTER_LIST.len()) return null;
	return CHAPTER_LIST[chapter_index];

}

// Returns the clicked button. Redisplays the question at timeout until the user answer the question.
function TestGame::ModalQuestion(text, buttons)
{
	local button = -1;
	while(true) // <-- redisplay the question at timeout rather than assuming a specific answer
	{
		local question_id = 0;
		local timeout = 60 * 3;
		GSGoal.Question(question_id, HUMAN_COMPANY, text, GSGoal.QT_QUESTION, buttons);
		button = this.WaitForButtonEvent(question_id, timeout);
		if(button != -1)
			break;
	}

	return button;
}

// This function eats all events while it is waiting for the question event!
// Returns -1 on timeout
// timeoutSeconds == -1 => no timeout
function TestGame::WaitForButtonEvent(questionUniqueId, timeoutSeconds)
{
	local start_time = GSDate.GetSystemTime();
	while(timeoutSeconds == -1 || start_time + timeoutSeconds > GSDate.GetSystemTime())
	{
		if(GSEventController.IsEventWaiting())
		{
			local ev = GSEventController.GetNextEvent();
			local ev_type = ev.GetEventType();

			if(ev_type == GSEvent.ET_GOAL_QUESTION_ANSWER)
			{
				local click_event = GSEventGoalQuestionAnswer.Convert(ev);
				if(click_event.GetUniqueID() == questionUniqueId)
					return click_event.GetButton();
			}
		}

		this.Sleep(1);
	}

	// Timeout
	return -1;
}

			


