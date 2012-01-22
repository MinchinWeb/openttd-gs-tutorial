
// Constants to use for the wait parameter of some tutorial step constructors
WAIT <- true
NO_WAIT <- false

// The uniqueid of the message window
MSG_WIN_UNIQUE_NUM <- 1;

// Encapsulate strings with this class to indicate that
// the string should be used as a key in the chapter
// storage table.
class TableKey
{
	_key = null;

	constructor(key)
	{
		_key = key;
	}
}

/*
 * Base class for all tutorial step classes
 */
class TutorialStep
{
	/*
	 * Pointer to a table in which the chapter can store
	 * data between the steps.
	 */
	_storage = null;

	constructor()
	{
	}

	/*
	 * This function should execute a tutorial step
	 * Eg. display a message, highlight a button and/or
	 * moving the screen.
	 * A Step may do just a single task or many things,
	 * but it should return when it is done and not
	 * wait for user feedback.
	 */
	function Execute() // override this
	{
	}

	/*
	 * After a step has been executed, the tutorial engine
	 * will poll this function to see if the step is done or not. 
	 * 
	 * This function should return true when the tutorial should
	 * progress to the next step. If you return false,
	 * the engine will check events etc. and then poll again.
	 *
	 * IsDone will/should never get called before Execute has been called.
	 */
	function IsDone() // override this
	{
		return true;
	}

	// don't override this function:
	function SetStorageTable(table)
	{
		this._storage = table;
	}

	// when the main loop detects an event, it is forwarded
	// to this function
	function Event(event)
	{
	}

	// Checks if the parameter is a TableKey and if so, it looks
	// up the value and returns it.
	function Evaluate(param)
	{
		// unfortunately typeof can't be used to check which class a instance is of.
		// so for now use the somewhat flawed method of checking if param is an instance that
		// has the _key member
		if(typeof(param) == "instance" && param.rawin("_key")) 
		//if(typeof(param) == "TableKey")
		{
			return this._storage.rawget(param._key);
		}
		else
		{
			return param;
		}
	}
}

/*
 * OrStep takes a number of step instances as argument.
 *
 * Eg. to wait for one of two windows:
 *   OrStep(WaitOnWindowStep(..), WaitOnWindowStep(other window))
 */
class OrStep extends TutorialStep
{
	_steps = null;

	constructor(...)
	{
		this._steps = [];

		// Read the variable parameters
		if(vargc > 0)
		{
			for(local c = 0; c < vargc; c++) {
				this._steps.append(vargv[c]);
			}
		}
	}

	function Execute();
	function IsDone();
	function Event(event);
}

function OrStep::Execute()
{
	foreach(step in this._steps)
	{
		step.Execute();
	}
}

function OrStep::IsDone()
{
	foreach(step in this._steps)
	{
		if(step.IsDone()) return true;
	}

	return false;
}

function OrStep::Event(event)
{
	foreach(step in this._steps)
	{
		step.Event(event);
	}
}

// Also, override the SetStorageTable function to pass the pointer along to the children
function OrStep::SetStorageTable(table)
{
	this._storage = table;
	foreach(step in this._steps)
	{
		step.SetStorageTable(table);
	}
}

/*
 * A SignMessageStep displays a message using signs and wait 
 * for the user to click on the continue button (a sign).
 */
class SignMessageStep extends TutorialStep
{
	_message = null;

	constructor(message)
	{
		this._message = message;
	}

	function Execute();
	function IsDone();
}

function SignMessageStep::Execute()
{
	// Evaluate params now (can't be done in the constructor as it can't access the storage table)
	this._message = this.Evaluate(this._message);

	local company_mode = GSCompanyMode(HUMAN_COMPANY);

	g_menu.Open(this._message, ["continue"]);
}

function SignMessageStep::IsDone()
{
	// This tutorial step is done when the user has closed the menu

	local company_mode = GSCompanyMode(HUMAN_COMPANY);

	local btn = g_menu.CheckInput();
	return btn != MENU_OPEN;
}

/*
 * A message window step displays a message window and wait for 
 * the user to click on the continue button.
 */
class MessageWindowStep extends TutorialStep
{
	_message = null;
	_window = null;
	_unique_id = null;
	_done = null;
	_wait_on_click = null;
	_param_list = null;

	// As variable parameters this tutorial step accepts parameters to GSText.
	// The parameter values can either be raw values or a TabelKey instance that
	// contains a string that is used as key in the chapter storage table. 
	//
	// Example:
	// In a previous CodeStep do:
	//    table.town <- 42;
	//
	// Then pass TableKey("town") as extra parameter to MessageWindowStep and it will
	// look up the value in the chapter storage and pass it to the GSText
	// instance.
	constructor(message, wait, ...)
	{
		this._message = message;
		this._done = false;
		this._wait_on_click = wait;

		// Read the variable parameters
		if(vargc > 0)
		{
			this._param_list = [];
			for(local c = 0; c < vargc; c++) {
				this._param_list.append(vargv[c]);
			}
		}

	}

	function Execute();
	function IsDone();
	function Event(event);
}
MessageStep <- MessageWindowStep; // old name

function MessageWindowStep::Execute()
{
	// Evaluate params now (can't be done in the constructor as it can't access the storage table)
	this._message = this.Evaluate(this._message);
	this._wait_on_click = this.Evaluate(this._wait_on_click);

	// Set GSText parameters if any additional parameters was passed to the constructor of this tutorial step
	if(this._param_list != null)
	{
		foreach(param in _param_list)
		{
			this._message.AddParam(this.Evaluate(param));
		}
	}

	// Open message window
	this._unique_id = MSG_WIN_UNIQUE_NUM;
	GSWindow.Close(GSWindow.WC_GOAL_QUESTION, this._unique_id); // close old window first
	GSGoal.Question(this._unique_id, HUMAN_COMPANY, this._message, GSGoal.QT_INFORMATION, GSGoal.BUTTON_CONTINUE);
}

function MessageWindowStep::IsDone()
{
	// This tutorial step is done when the user has answered the question
	return !this._wait_on_click || this._done ||
		!GSWindow.IsOpen(GSWindow.WC_GOAL_QUESTION, this._unique_id); // also check if the window was closed without pressing one of the answer buttons.
}

function MessageWindowStep::Event(event)
{
	local ev_type = event.GetEventType();

	if(ev_type == GSEvent.ET_GOAL_QUESTION_ANSWER)
	{
		local click_event = GSEventGoalQuestionAnswer.Convert(event);

		// As we only use one button "continue", don't validate the button ID sent from OpenTTD.
		// also the tutorial assume that there is only one company and only one player.
		if(click_event.GetUniqueID() == this._unique_id)
		{
			this._done = true;
		}

		Log.Info("User answered question: id: " + click_event.GetUniqueID() + " button: " + click_event.GetButton() + " company: " + click_event.GetCompany(), Log.LVL_DEBUG);
	}
}

/*
 * A close window step closes a specific window and is then done
 */
class CloseWindowStep extends TutorialStep
{
	_window_class = null;
	_window_number = null;

	constructor(window_class, window_number)
	{
		this._window_class = window_class;
		this._window_number = window_number;
	}

	function Execute();
	function IsDone();
}

function CloseWindowStep::Execute()
{
	// Evaluate params now (can't be done in the constructor as it can't access the storage table)
	this._window_class = this.Evaluate(this._window_class);
	this._window_number = this.Evaluate(this._window_number);

	// Close window
	GSWindow.Close(this._window_class, this._window_number);
}

function CloseWindowStep::IsDone()
{
	// Done after execution
	return true;
}

/*
 * A CloseMessageWindowStep is used to close windows opened by MessageWindowStep
 */
class CloseMessageWindowStep extends CloseWindowStep
{
	constructor()
	{
		::CloseWindowStep.constructor(GSWindow.WC_GOAL_QUESTION, MSG_WIN_UNIQUE_NUM)
	}
}

/*
 * A WaitOnWindowStep is used to wait for a window to open or close
 */
WAIT_ON_CLOSE <- "close";
WAIT_ON_OPEN <- "open";
class WaitOnWindowStep extends TutorialStep
{
	_window_class = null;
	_window_number = null;
	_wait_on = null;

	constructor(window_class, window_number, wait_on)
	{
		this._window_class = window_class;
		this._window_number = window_number;
		this._wait_on = wait_on;
	}

	function Execute();
	function IsDone();
}

function WaitOnWindowStep::Execute()
{
	// Evaluate params now (can't be done in the constructor as it can't access the storage table)
	this._window_class = this.Evaluate(this._window_class);
	this._window_number = this.Evaluate(this._window_number);
	this._wait_on = this.Evaluate(this._wait_on);
}

function WaitOnWindowStep::IsDone()
{
	local is_open = GSWindow.IsOpen(this._window_class, this._window_number);

	return (is_open && this._wait_on == WAIT_ON_OPEN) ||
		(!is_open && this._wait_on == WAIT_ON_CLOSE);
}

/*
 * A code step takes a function that is executed when this step
 * is executed
 */
class CodeStep extends TutorialStep
{
	_function = null;

	constructor(func)
	{
		this._function = func;
	}

	function Execute();
	function IsDone();
}

function CodeStep::Execute()
{
	this._function(this._storage);
}

function CodeStep::IsDone()
{
	return true;
}

/*
 * A gui highlight step flashes a GUI button and ends
 * when that GUI button is clicked by a user.
 *
 * The click event is catched by the main
 * loop which 
 */
class GUIHighlightStep extends TutorialStep
{
	_window_class = null;
	_window_number = null;
	_button = null;
	_wait_on_click = null;

	_clicked = false;

	constructor(window_class, window_number, button, wait = true)
	{
		this._window_class = window_class;
		this._window_number = window_number;
		this._button = button;
		this._wait_on_click = wait;
	}

	function Execute();
	function IsDone();
	function Event(event);
}

function GUIHighlightStep::Execute()
{
	// Evaluate params now (can't be done in the constructor as it can't access the storage table)
	this._window_class = this.Evaluate(this._window_class);
	this._window_number = this.Evaluate(this._window_number);
	this._button = this.Evaluate(this._button);
	this._wait_on_click = this.Evaluate(this._wait_on_click);

	// Wait in up to 74 ticks (1 day) for the window to open.
	//
	// The idea is that you should be able to put several GUIHighlightSteps after each other without having to insert
	// tutorial steps in between to wait for OpenTTD to open the window as a result of the user clicking on the button.
	// Instead this TutorialStep can wait a short amount of time if needed, but not forever.
	local tick = GSController.GetTick();
	while(!GSWindow.IsOpen(this._window_class, this._window_number)) { 
		GSController.Sleep(1); 

		if(GSController.GetTick() > tick + 74) 
		{
			Log.Warning("The window to highlight is not open. Waiting has timed out. window class: " + this._window_class + " number: " + this._window_number + " widget: " + this._button, Log.LVL_DEBUG);
			break;
		}
	}

	GSWindow.Highlight(this._window_class, this._window_number, this._button, GSWindow.TC_DARK_BLUE);
	Log.Info("Wait for click on: window: " + this._window_class + " number: " + this._window_number + " widget: " + this._button, Log.LVL_DEBUG);
}

function GUIHighlightStep::IsDone()
{
	return !this._wait_on_click || this._clicked;
}

function GUIHighlightStep::Event(event)
{
	local ev_type = event.GetEventType();

	if(ev_type == GSEvent.ET_WINDOW_WIDGET_CLICK)
	{
		local click_event = GSEventWindowWidgetClick.Convert(event);

		if(click_event.GetWindowClass() == this._window_class &&
				click_event.GetWindowNumber() == this._window_number &&
				click_event.GetWidgetNumber() == this._button)
		{
			this._clicked = true;

			// Stop the highlight
			GSWindow.Highlight(this._window_class, this._window_number, this._button, GSWindow.TC_INVALID);
		}

		Log.Info("User clicked at: window: " + click_event.GetWindowClass() + " number: " + click_event.GetWindowNumber() + " widget: " + click_event.GetWidgetNumber(), Log.LVL_DEBUG);
	}
}

