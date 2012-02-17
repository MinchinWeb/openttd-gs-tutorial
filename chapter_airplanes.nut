
class ChapterAirplanes {

	constructor() {
	}

	static function ID();
	static function LoadChapter(main_instance);
}

/*static*/ function ChapterAirplanes::ID()
{
	return "airplanes";
}

/*static*/ function ChapterAirplanes::LoadChapter(main_instance)
{
	// Initialization code
	main_instance.AddStep(CodeStep( function(table) {

		// For now just hardcode town id 0 and 2
		table.town_a <- 0;
		table.town_b <- 2;

	}));

	// 1.1 First airport
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_1_1_INTRO), WAIT, TableKey("town_a")));
	main_instance.AddStep(CodeStep( function(table) {
		GSViewport.ScrollTo(GSTown.GetLocation(table.town_a)); // scroll viewport to town A
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_1_2_PLACEMENT), NO_WAIT));
	main_instance.AddStep(ConditionalStep(function(table) { return !GSWindow.IsOpen(GSWindow.WC_BUILD_TOOLBAR, 3); },
		GUIHighlightStep(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_AIR)));
	main_instance.AddStep(ConditionalStep(function(table) { return !GSWindow.IsOpen(GSWindow.WC_BUILD_STATION, 3); },
		GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 3, GSWindow.WID_AT_AIRPORT)));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_STATION, 3, GSWindow.WID_AP_BTN_DOHILIGHT, NO_WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_1_3_ACCEPTANCE), WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_1_4_ACCEPTANCE), WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_1_5_PLACE_AP), NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		ChapterAirplanes.WaitForAirportInTown(table.town_a);
	}));
	main_instance.AddStep(CloseMessageWindowStep()); // close message if user didn't close it
	// close build windows, so the user get to find them again (with guidance)
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_STATION, 3)); 
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_TOOLBAR, 3)); 

	// 1.2 Second airport
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_2_1_WHERE), WAIT, TableKey("town_b")));
	main_instance.AddStep(CodeStep( function(table) {
		GSViewport.ScrollTo(GSTown.GetLocation(table.town_b)); // scroll viewport to town B
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_2_2_BUILD), WAIT, TableKey("town_b"), TableKey("town_a")));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_AIR));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 3, GSWindow.WID_AT_AIRPORT, NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		ChapterAirplanes.WaitForAirportInTown(table.town_b);
	}));
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_STATION, 3)); // clear up some windows
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_TOOLBAR, 3)); 

	// 1.3 Aircraft
	main_instance.AddStep(CodeStep( function(table) {
		// Record the two airport stations so they can be referred to in messages
		table.airport_a <- ChapterAirplanes.GetAirportInTown(table.town_a);
		table.airport_b <- ChapterAirplanes.GetAirportInTown(table.town_b);

		GSViewport.ScrollTo(GSTown.GetLocation(table.town_b)); // scroll viewport to town B
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_3_1_HANGAR), NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) { 
		// build sign and wait for window to open
		local hangar_tile = GSAirport.GetHangarOfAirport(GSStation.GetLocation(table.airport_b));
		Helper.SetSign(hangar_tile, GSText(GSText.STR_AIRPLANES_HANGAR_SIGN), true);
		table.hangar_b <- hangar_tile; // allow access from tutorial step as the depot window will use the same window number as the depot tile
	}));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_VEHICLE_DEPOT, TableKey("hangar_b"), WAIT_ON_OPEN)); // wait for hangar window to open
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_3_2_BUY), NO_WAIT)); // ask to click build aircraft
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_DEPOT, TableKey("hangar_b"), GSWindow.WID_D_BUILD));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_3_3_SELECT_AIRCRAFT), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_VEHICLE, TableKey("hangar_b"), GSWindow.WID_BV_LIST, NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) { // wait a short while
		GSController.Sleep(8);
	}));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_VEHICLE, TableKey("hangar_b"), GSWindow.WID_BV_BUILD, NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) { // wait for aircraft to be built
		local company_mode = GSCompanyMode(HUMAN_COMPANY);
		while(true)
		{
			local veh_list = GSVehicleList();
			veh_list.Valuate(GSVehicle.GetVehicleType);
			veh_list.KeepValue(GSVehicle.VT_AIR);
			if(!veh_list.IsEmpty())
			{
				// Record the vehicle id of the aircraft
				table.aircraft <- veh_list.Begin();
				return;
			}
		}
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_3_4_ORDERS), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_VIEW, TableKey("aircraft"), GSWindow.WID_VV_SHOW_ORDERS, WAIT));

	// conditionally show a message to click on goto if quick goto is off.
	main_instance.AddStep(ConditionalStep(function(table) { return GSGameSettings.GetValue("quick_goto") == 0 }, 
		MessageWindowStep(GSText(GSText.STR_AIRPLANES_CLICK_GO_TO), NO_WAIT)));
	main_instance.AddStep(ConditionalStep(function(table) { return GSGameSettings.GetValue("quick_goto") == 0 }, 
		GUIHighlightStep(GSWindow.WC_VEHICLE_ORDERS, TableKey("aircraft"), GSWindow.WID_O_GOTO, WAIT)));

	// temporary use WAIT for this step, until OpenTTD supports waiting for an order to exist
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_3_5_ORDERS), NO_WAIT, TableKey("town_b"))); // click on ap in town b
	main_instance.AddStep(CodeStep( function(table) { // wait for order list to contain one order to airport b
		ChapterAirplanes.WaitForOrderToAirport(table.aircraft, table.airport_b);
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_3_6_STATION_LIST), NO_WAIT, TableKey("town_a")));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_STATIONS, WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_STATION_LIST, HUMAN_COMPANY, GSWindow.WID_STL_LIST, NO_WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_3_7_STATION_LIST), WAIT, TableKey("airport_a")));

	// click on goto again if quick goto is off
	main_instance.AddStep(ConditionalStep(function(table) { return GSGameSettings.GetValue("quick_goto") == 0 }, 
		MessageWindowStep(GSText(GSText.STR_AIRPLANES_CLICK_GO_TO), NO_WAIT)));
	main_instance.AddStep(ConditionalStep(function(table) { return GSGameSettings.GetValue("quick_goto") == 0 }, 
		GUIHighlightStep(GSWindow.WC_VEHICLE_ORDERS, TableKey("aircraft"), GSWindow.WID_O_GOTO, WAIT)));

	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_3_8_ORDERS), NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) { // wait for order list to contain one order to airport a
		ChapterAirplanes.WaitForOrderToAirport(table.aircraft, table.airport_a);
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_3_9_START_AIRCRAFT), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_VIEW, TableKey("aircraft"), GSWindow.WID_VV_START_STOP, WAIT));


	// 1.4 - Sum up
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_4_1_SUM_UP), NO_WAIT));
	main_instance.AddStep(
		OrStep( // Wait for station window for either of the two airports to open OR that the user clicks continue
			WaitOnWindowStep(GSWindow.WC_STATION_VIEW, TableKey("airport_a"), WAIT_ON_OPEN),
			WaitOnWindowStep(GSWindow.WC_STATION_VIEW, TableKey("airport_b"), WAIT_ON_OPEN),
			WaitOnWindowStep(GSWindow.WC_GOAL_QUESTION, MSG_WIN_UNIQUE_NUM, WAIT_ON_CLOSE)
		)
	);
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_4_2_STATION_WINDOW), WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_4_3_AIRCRAFT_PROFIT), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_VIEW, TableKey("aircraft"), GSWindow.WID_VV_SHOW_DETAILS, WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_4_4_AIRCRAFT_PROFIT), WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_AIRPLANES_1_4_5_DONE), WAIT));
}

/*static*/ function ChapterAirplanes::WaitForAirportInTown(town)
{
	local start_time = GSDate.GetSystemTime();
	local message = false;
	local message_id = 2; // used as uniqueid for GSGoal.Question
	while (ChapterAirplanes.GetAirportInTown(town) == -1) // do not use GSStation.IsValidStation here as that will probably need a GSCompanyMode, but GSGoal.Question can't be used when a company mode is active.
	{
		if(!message && 
				start_time + 30 < GSDate.GetSystemTime() && 
				!GSWindow.IsOpen(GSWindow.WC_GOAL_QUESTION, MSG_WIN_UNIQUE_NUM)) // require the main timeline message to be closed in order to show the notification window
		{
			// The user might not know that we are waiting
			message = GSGoal.Question(message_id, HUMAN_COMPANY, GSText(GSText.STR_AIRPLANES_NOTICE_WAITING_FOR_AP_BUILD, town), GSGoal.QT_INFORMATION, GSGoal.BUTTON_CLOSE);
		}

		GSController.Sleep(1);
	}

	// Close the notification about waiting for airport construction if it has been shown
	if(message)
		GSGoal.CloseQuestion(message_id);
}

/*static*/ function ChapterAirplanes::GetAirportInTown(town)
{
	local company_mode = GSCompanyMode(HUMAN_COMPANY);
	local st_list = GSStationList(GSStation.STATION_AIRPORT);

	st_list.Valuate(GSStation.GetNearestTown);
	st_list.KeepValue(town);

	if(!st_list.IsEmpty())
	{
		return st_list.Begin();
	}

	return -1;
}

/*static*/ function ChapterAirplanes::WaitForOrderToAirport(aircraft, station_id)
{
	local company_mode = GSCompanyMode(HUMAN_COMPANY);
	local message_id = 2;
	local message = false;
	while(true)
	{
		for(local i = 0; i < GSOrder.GetOrderCount(aircraft); i++)
		{
			if(GSOrder.IsGotoStationOrder(aircraft, i) &&
					GSStation.GetStationID(GSOrder.GetOrderDestination(aircraft, i)) == station_id)
			{
				return;
			}
			else if(!message && GSOrder.IsGotoDepotOrder(aircraft, i))
			{
				company_mode = null;

				// GSGoal.Question don't work with a company mode active
				message = GSGoal.Question(message_id, HUMAN_COMPANY, GSText(GSText.STR_AIRPLANES_NOTICE_HANGAR_ORDER, station_id), GSGoal.QT_WARNING, GSGoal.BUTTON_CLOSE);
				company_mode = GSCompanyMode(HUMAN_COMPANY);


				local order_count = GSOrder.GetOrderCount(aircraft);
				GSWindow.Highlight(GSWindow.WC_VEHICLE_ORDERS, aircraft, GSWindow.WID_O_ORDER_LIST, GSWindow.TC_DARK_BLUE);
				GSWindow.Highlight(GSWindow.WC_VEHICLE_ORDERS, aircraft, GSWindow.WID_O_DELETE, GSWindow.TC_DARK_BLUE);
				while(GSOrder.GetOrderCount(aircraft) == order_count) { GSController.Sleep(1); } // wait until order has been removed
				GSWindow.Highlight(GSWindow.WC_VEHICLE_ORDERS, aircraft, GSWindow.WID_O_GOTO, GSWindow.TC_DARK_BLUE);

			}
		}

		GSController.Sleep(1);
	}
}
