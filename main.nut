/* Include Tutorial files */
require("menu.nut");
require("tutorial_step.nut");
require("chapter_intro.nut");
require("chapter_airplanes.nut");
require("chapter_ships.nut");
require("chapter_road_vehicles.nut");
require("chapter_trains.nut");

/* Import SuperLib for GameScript */
import("util.superlib", "SuperLib", 18);
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
		if (this.LoadChapter(this._load_data.chapter))
		{
			// Set current step to the step it had when the game was saved
			this._current_step = this._load_data.step; 

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

function TestGame::InitBeforeNewChapter()
{
	this._chapter_steps = [];
	this._current_step = -1;
	this._chapter_storage = {}; // Table which all chapter steps can access to store data
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
			GSGoal.Question(0, HUMAN_COMPANY, GSText(GSText.STR_NO_MORE_CHAPTERS), GSGoal.BUTTON_CLOSE);
			this._end_of_tutorial = true;
		}
	}

	// Is current step done?
	if(this._current_step < 0 || this._chapter_steps[this._current_step].IsDone())
	{
		this._current_step++;

		// reached end of tutorial?
		if(this._current_step >= this._chapter_steps.len())
			return;

		// Execute next step
		this._chapter_steps[this._current_step].Execute();
	}
}

function TestGame::Save()
{
	return { 
		chapter = "bus",
  		step = this._current_step
	};
}

function TestGame::Load(tbl, version)
{
	// Store a copy of the table from the save game
	this._load_data = { 
		chapter = tbl.chapter,
		step = tbl.step
	};
}

/*
 * -------- Chapters ---------------------------------
 */
function TestGame::LoadChapter(chapter)
{
	// Unload old chapter
	this.InitBeforeNewChapter();

	if(chapter == null) return false;

	// Load new chapter
	this._current_chapter_id = chapter.ID();
	chapter.LoadChapter(this);

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


