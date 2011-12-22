
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
}

/*
 * A message step displays a message and wait for the user to
 * click on the continue button.
 */
class MessageStep extends TutorialStep
{
	_message = null;

	constructor(message)
	{
		this._message = message;
	}

	function Execute();
	function IsDone();
}

function MessageStep::Execute()
{
	g_menu.Open(this._message, ["continue"]);
}

function MessageStep::IsDone()
{
	// This tutorial step is done when the user has closed the menu
	local btn = g_menu.CheckInput();
	return btn != MENU_OPEN;
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
 * A code step flashes a GUI button and ends
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

	_clicked = false;

	constructor(window_class, window_number, button)
	{
		this._window_class = window_class;
		this._window_number = window_number;
		this._button = button;
	}

	function Execute();
	function IsDone();
	function Event(event);
}

function GUIHighlightStep::Execute()
{
	GSWindow.Highlight(this._window_class, this._window_number, this._button, GSWindow.TC_DARK_BLUE);
	Log.Info("Wait for click on: window: " + this._window_class + " number: " + this._window_number + " widget: " + this._button);
}

function GUIHighlightStep::IsDone()
{
	return this._clicked;
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

		Log.Info("User clicked at: window: " + click_event.GetWindowClass() + " number: " + click_event.GetWindowNumber() + " widget: " + click_event.GetWidgetNumber());
	}
}
