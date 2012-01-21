/* Include Tutorial files */
require("menu.nut");
require("tutorial_step.nut");
require("chapter_intro.nut");
require("chapter_airplanes.nut");
require("chapter_ships.nut");
require("chapter_road_vehicles.nut");
require("chapter_trains.nut");

/* Import SuperLib for GameScript */
import("util.superlib", "SuperLib", 19);
Result <- SuperLib.Result;
Log <- SuperLib.Log;
Helper <- SuperLib.Helper;
ScoreList <- SuperLib.ScoreList;
Tile <- SuperLib.Tile;
Direction <- SuperLib.Direction;
Town <- SuperLib.Town;
Industry <- SuperLib.Industry;

/* Globals */
g_menu <- null;
HUMAN_COMPANY <- 0;
CHAPTER_LIST <- [ ChapterIntro, ChapterAirplanes, ChapterShips, ChapterRoadVehicles, ChapterTrains ];
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
	// Check for multiplayer game
	if(GSGame.IsMultiplayer())
	{
		this.Sleep(1); // start game

		// Report problem
		Log.Error("Error: Tutorial can't be run in multiplayer");
		while(true)
		{
			GSGoal.Question(0, GSCompany.COMPANY_INVALID, GSText(GSText.STR_ERROR_MULTIPLAYER), GSGoal.QT_ERROR, GSGoal.BUTTON_CLOSE);
			this.Sleep(10);
		}
	}


	// Any GameScript init code goes here
	this.Init();

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
	g_menu = Menu();
	this._end_of_tutorial = false;

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
	};

}

function TestGame::Load(version, tbl)
{
	Log.Info("Loading data from savegame of tutorial version: " + version, Log.LVL_INFO);
	Log.Info("chapter: " + tbl.chapter, Log.LVL_INFO);
	Log.Info("step: " + tbl.step, Log.LVL_INFO);
	// Store a copy of the table from the save game
	this._load_data = { 
		chapter = tbl.chapter,
		step = tbl.step,
		chapter_storage = tbl.chapter_storage,
	};
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
	local index = TestGame.GetChapterIndex(chapter_id);
	if(index < 0) return null;
	if(index + 1 >= CHAPTER_LIST.len()) return null;
	return CHAPTER_LIST[index + 1];
}


