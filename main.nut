/* Include Tutorial files */
require("menu.nut");
require("tutorial_step.nut");
require("chapter_bus.nut");

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


class TestGame extends GSController 
{
	_chapter_steps = null;
	_current_step = null;

	_chapter_storage = null;

	_load_data = null;

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
	local company_mode = GSCompanyMode(0);

	Log.Info("Tutorial starts now", Log.LVL_INFO);

	while (true) {
		this.HandleEvents();
		this.RunTutorial();
		this.Sleep(10);
	}
}

function TestGame::Init()
{
	g_menu = Menu();

	this.InitBeforeNewChapter();

	local loaded_state = false;
	if(this._load_data != null)
	{
		if(this._load_data.chapter == "bus")
		{
			// Set current step to the step it had when the game was saved
			this._current_step = this._load_data.step; 

			// Load the bus chapter
			this.LoadBusChapter();

			loaded_state = true;
		}
	}

	if(!loaded_state)
	{
		// No tutorial state was loaded from save
		// => Start from the beginning (in future: possible show a menu of chapters)
		this.LoadBusChapter();
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
	// Is tutorial already done?
	if(this._current_step >= this._chapter_steps.len())
		return;

	// Is last step done?
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
function TestGame::LoadBusChapter()
{
	ChapterBus.LoadBusChapter(this);
/*
	this.AddStep(MessageStep("Bus service\n\n" +
			"In this chapter a first transport service will be setup using buses to transport passengers between two towns."));
	this.AddStep(CodeStep(function(table) {

		table.abc <- [];
} ));
	this.AddStep(MessageStep("The first step is to find two suitable towns. In this tutorial the towns marked with TOWN A and TOWN B signs will be connected.\n\nNext menu will be displayed near Town A"));
	this.AddStep(MessageStep("A bus service needs bus stops where passengers will wait and the buses will stop and pick up the passengers. When you click on continue, a bus stop will be placed in Town A."));
	this.AddStep(MessageStep("When you click continue, a bus stop will be placed in Town B"));
	this.AddStep(MessageStep("Now both towns have a bus stop to collect passengers. Next a road has to be built to connect the two towns.\n\nWhen you click on continue a road will be built between the towns. This may take some time."));
*/
}

