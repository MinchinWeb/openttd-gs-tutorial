
class ChapterShips {

	constructor() {
	}

	static function ID();
	static function LoadChapter(main_instance);
}

/*static*/ function ChapterShips::ID()
{
	return "ships";
}

/*static*/ function ChapterShips::LoadChapter(main_instance)
{
	// Initialization code
	main_instance.AddStep(CodeStep( function(table) {

		// Industry index 0
		table.refinery <- 0;

		// Industry index 1 and 2
		table.oilrig1 <- 1;
		table.oilrig2 <- 2;

		// station IDs for the oilrig stations
		table.oilrig1_station <- GSStation.GetStationID(GSIndustry.GetDockLocation(table.oilrig1));
		table.oilrig2_station <- GSStation.GetStationID(GSIndustry.GetDockLocation(table.oilrig2));

		// canal start/end
		table.canal_start_tile <- g_tile_labels.GetTile("CanalStart");
		table.canal_end_tile <- g_tile_labels.GetTile("CanalEnd");
		table.canal_lock1 <- g_tile_labels.GetTile("CanalLock1");
		table.canal_lock2 <- g_tile_labels.GetTile("CanalLock2");
	}));

	// 2.1 - Ship dock construction (for refinery)
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_1_1), WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		GSViewport.ScrollTo(GSIndustry.GetLocation(table.refinery)); // scroll viewport to the oil refinery
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_1_2), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_WATER));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_BUILD_TOOLBAR, 2, WAIT_ON_OPEN));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_1_3), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 2, GSWindow.WID_DT_STATION, NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		// todo: make WaitForDockForIndustry allow docks that doesn't cover top tile of industry.
		ChapterShips.WaitForDockForIndustry(table.refinery);
		table.refinery_dock <- ChapterShips.GetDockForIndustry(table.refinery);
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_1_4), WAIT));

	//main_instance.AddStep(CloseMessageWindowStep()); // close message if user didn't close it
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_STATION, 2)); // close windows from dock construction
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_TOOLBAR, 2)); 

	// 2.2 - Ship depot construction
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_2_1), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_WATER));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_BUILD_TOOLBAR, 2, WAIT_ON_OPEN));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 2, GSWindow.WID_DT_DEPOT, WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_2_2), NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		ChapterShips.WaitForShipyard();
		table.shipyard <- ChapterShips.GetShipyard();
	}));

	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_STATION, 2)); // close windows from shipyard construction
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_TOOLBAR, 2)); 

	// 2.3 - Buying a ship and giving it orders
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_3_1), NO_WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_VEHICLE_DEPOT, TableKey("shipyard"), WAIT_ON_OPEN)); // while there is no text guidance in this chapter, provide highlights.
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_DEPOT, TableKey("shipyard"), GSWindow.WID_D_BUILD, WAIT));
	//main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_VEHICLE, TableKey("shipyard"), GSWindow.WID_BV_LIST, NO_WAIT)); // no click is required
	main_instance.AddStep(CodeStep( function(table) { // wait a short while
		GSController.Sleep(8);
	}));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_VEHICLE, TableKey("shipyard"), GSWindow.WID_BV_BUILD, NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		ChapterShips.WaitForOilShip();
		table.ship1 <- ChapterShips.GetOilShip();
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_3_2), WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		local station_loc = GSIndustry.GetDockLocation(table.oilrig1);
		GSViewport.ScrollTo(GSIndustry.GetLocation(table.oilrig1)); // scroll viewport to the oilrig
		GSController.Sleep(25); // sleep a short while
		GSSign.BuildSign(station_loc, GSText(GSText.STR_SHIPS_SIGN_OILRIG_STATION)); // put a sign ontop of the station tile
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_3_3), NO_WAIT, TableKey("oilrig1_station"), TableKey("refinery_dock")));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_VEHICLE_VIEW, TableKey("ship1"), WAIT_ON_OPEN)); // ensure that the vehicle window is open before waiting for click on orders button
	main_instance.AddStep(ConditionalStep(function(table) { return !GSWindow.IsOpen(GSWindow.WC_VEHICLE_ORDERS, table.ship1); },
		GUIHighlightStep(GSWindow.WC_VEHICLE_VIEW, TableKey("ship1"), GSWindow.WID_VV_SHOW_ORDERS, WAIT))); // highlight btn to open orders window only if it is not open
	main_instance.AddStep(ConditionalStep(function(table) { return GSGameSettings.GetValue("quick_goto") == 0 }, 
		GUIHighlightStep(GSWindow.WC_VEHICLE_ORDERS, TableKey("ship1"), GSWindow.WID_O_GOTO, NO_WAIT)));
	main_instance.AddStep(CodeStep( function(table) {
		Common.WaitForOrderToStations(table.ship1, [table.refinery_dock, table.oilrig1_station],
			GSText(GSText.STR_SHIPS_NOTICE_WAITING_FOR_ORDERS, table.ship1, table.oilrig1_station, table.refinery_dock));
	}));

	// 2.4 - The first order flag
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_4_1), NO_WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_VEHICLE_VIEW, TableKey("ship1"), WAIT_ON_OPEN)); // ensure that the vehicle window is open before waiting for click on start/stop button
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_VIEW, TableKey("ship1"), GSWindow.WID_VV_START_STOP, WAIT)); 
	main_instance.AddStep(CodeStep( function(table) {
		ChapterShips.WaitForShipLeavingOilrigSecondTime(table);
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_4_2), NO_WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_VEHICLE_VIEW, TableKey("ship1"), WAIT_ON_OPEN)); // ensure that the vehicle window is open before waiting for click
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_VIEW, TableKey("ship1"), GSWindow.WID_VV_SHOW_DETAILS, WAIT)); 
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_4_3), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_VIEW, TableKey("ship1"), GSWindow.WID_VV_SHOW_ORDERS, WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_4_4), NO_WAIT, TableKey("oilrig1_station"))); // click on oil rig order
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_ORDERS, TableKey("ship1"), GSWindow.WID_O_ORDER_LIST, WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_4_5), WAIT)); // inform about buttons at bottom
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_4_6), NO_WAIT)); // ask to click on full load any cargo
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_ORDERS, TableKey("ship1"), GSWindow.WID_O_FULL_LOAD, WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_4_7), WAIT)); // inform user what happened

	// 2.5 - canals
	main_instance.AddStep(CodeStep( function(table) {
		// Place signs where the canal should start/end
		Helper.SetSign(table.canal_start_tile, GSText(GSText.STR_SHIPS_SIGN_CANAL_START));
		Helper.SetSign(table.canal_end_tile, GSText(GSText.STR_SHIPS_SIGN_CANAL_END));
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_5_1), WAIT)); // intro to canals
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_5_2), NO_WAIT)); // select canal tool
	main_instance.AddStep(ConditionalStep(function(table) { return !GSWindow.IsOpen(GSWindow.WC_BUILD_TOOLBAR, 2); }, // highlight button to open water toolbar if it is not already open
		GUIHighlightStep(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_WATER, WAIT)));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_BUILD_TOOLBAR, 2, WAIT_ON_OPEN));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 2, GSWindow.WID_DT_CANAL, WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_5_3), NO_WAIT)); // connect highlighted tiles
	// todo: detect that the two tiles are connected with canal tiles
	main_instance.AddStep(CodeStep( function(table) {
		// wait on canal to be built
		ChapterShips.WaitForCanal(table.canal_start_tile, table.canal_end_tile);

		// remove canal signs
		Helper.SetSign(table.canal_start_tile, "");
		Helper.SetSign(table.canal_end_tile, "");
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_5_4), NO_WAIT)); // lock tool
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 2, GSWindow.WID_DT_LOCK, WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		// put signs at the lock tiles
		Helper.SetSign(table.canal_lock1, GSText(GSText.STR_SHIPS_SIGN_LOCK1));
		Helper.SetSign(table.canal_lock2, GSText(GSText.STR_SHIPS_SIGN_LOCK2));
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_5_5), NO_WAIT)); // place lock
	main_instance.AddStep(CodeStep( function(table) {
		// wait for locks
		ChapterShips.WaitForLock(table.canal_lock1);
		ChapterShips.WaitForLock(table.canal_lock2);

		// remove lock signs
		Helper.SetSign(table.canal_lock1, "");
		Helper.SetSign(table.canal_lock2, "");
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_5_6), WAIT)); // summary of canals

	// 2.6 - end of this chapter
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_6_1), WAIT));
}

/*static*/ function ChapterShips::WaitForDockForIndustry(industry)
{
	ChapterShips.WaitFor(ChapterShips.GetDockForIndustry, [industry], GSText(GSText.STR_SHIPS_NOTICE_WAITING_FOR_DOCK_BUILD, industry));
}

/*static*/ function ChapterShips::DockInTileArea(station, tile_list)
{
	return tile_list.HasItem(GSStation.GetLocation(station));
}

/*static*/ function ChapterShips::GetDockForIndustry(industry)
{
	local company_mode = GSCompanyMode(HUMAN_COMPANY);
	local st_list = GSStationList(GSStation.STATION_DOCK);
	local allowed_dock_tiles = GSTileList_IndustryAccepting(industry, GSStation.GetCoverageRadius(GSStation.STATION_DOCK));

	st_list.Valuate(ChapterShips.DockInTileArea, allowed_dock_tiles);
	st_list.KeepValue(1);

	if(st_list.IsEmpty())
		return -1;

	return st_list.Begin();
}

/*static*/ function ChapterShips::WaitForShipyard()
{
	ChapterShips.WaitFor(ChapterShips.HaveShipyard, [], GSText(GSText.STR_SHIPS_NOTICE_WAITING_FOR_SHIP_YARD_BUILD));
}

/*static*/ function ChapterShips::HaveShipyard()
{
	return ChapterShips.GetShipyard() != -1;
}

/*static*/ function ChapterShips::GetShipyard()
{
	local company_mode = GSCompanyMode(HUMAN_COMPANY);
	local depot_list = GSDepotList(GSTile.TRANSPORT_WATER);

	if(depot_list.IsEmpty())
		return -1;

	return depot_list.Begin();
}

/*static*/ function ChapterShips::WaitForOilShip()
{
	ChapterShips.WaitFor(ChapterShips.HaveOilShip, [], GSText(GSText.STR_SHIPS_NOTICE_WAITING_FOR_OIL_SHIP));
}

/*static*/ function ChapterShips::HaveOilShip()
{
	return ChapterShips.GetOilShip() != -1;
}

// Copied from SuperLib for AIs 
/*static*/ function ChapterShips::GetVehicleCargo(vehicle_id)
{
	// Go through all cargos and check the capacity for each
	// cargo.
	local max_cargo = -1;
	local max_cap = -1;

	local cargos = GSCargoList();
	foreach(cargo, _ in cargos)
	{
		local cap = GSVehicle.GetCapacity(vehicle_id, cargo);
		if(cap > max_cap)
		{
			max_cap = cap;
			max_cargo = cargo;
		}
	}

	return max_cargo;
}

/*static*/ function ChapterShips::GetOilCargo()
{
	local cargo_list = GSCargoList();
	foreach(cargo, _ in cargo_list)
	{
		if(GSCargo.GetCargoLabel(cargo) == "OIL_")
		{
			return cargo;
		}
	}

	return -1;
}

/*static*/ function ChapterShips::GetOilShip()
{
	local company_mode = GSCompanyMode(HUMAN_COMPANY);
	local veh_list = GSVehicleList();
	local oil_cargo = ChapterShips.GetOilCargo();
	veh_list.Valuate(ChapterShips.GetVehicleCargo);
	veh_list.KeepValue(oil_cargo);

	if(veh_list.IsEmpty())
		return -1;

	return veh_list.Begin();
}

/*static*/ function ChapterShips::WaitForShipLeavingOilrigSecondTime(table)
{
	// Wait until the ship has left the oil rig for the second time
	local leave_rig_times = 0; 
	local leave_refinery_times = 0; 
	local last_at = "shipyard"; 
	local oilrig_station_loc = GSIndustry.GetDockLocation(table.oilrig1); 
	local refinery_station_loc = GSStation.GetLocation(table.refinery_dock);
	while(leave_rig_times < 2 || leave_refinery_times < 1) {
		// Get distance to rig and refinery
		local rig_dist = GSMap.DistanceManhattan(oilrig_station_loc, GSVehicle.GetLocation(table.ship1)); 
		local refinery_dist = GSMap.DistanceManhattan(refinery_station_loc, GSVehicle.GetLocation(table.ship1));

		// At rig or refinery?
		local at = ""; 
		if(rig_dist <= 4)
			at = "rig"; 
		else if(refinery_dist <= 4)
			at = "refinery";

		// Left something?
		if(at != last_at) 
		{ 
			if(at == "" && last_at == "rig") leave_rig_times++;
			if(at == "" && last_at == "refinery") leave_refinery_times++;

			last_at = at; 
		}

		GSController.Sleep(1); 
	} 
}

/*static*/ function ChapterShips::WaitForCanal(fromTile, toTile)
{
	ChapterShips.WaitFor(ChapterShips.HaveCanal, [fromTile, toTile], GSText(GSText.STR_SHIPS_NOTICE_WAITING_FOR_CANAL));
}

/*static*/ function ChapterShips::HaveCanal(fromTile, toTile)
{
	if(fromTile == toTile) return true;

	//local company_mode = GSCompanyMode(HUMAN_COMPANY); // not needed for canals
	local open_list = GSList();
	local closed_list = GSList();
	
	// Init
	local curr_tile = fromTile;
	closed_list.AddItem(curr_tile, 0);

	while(true)
	{
		// Add the neighbours of current tile that have not been visited to open_list
		local neighbours = Tile.GetNeighbours4MainDir(curr_tile);
		neighbours.RemoveList(closed_list);
		neighbours.Valuate(GSMarine.IsCanalTile);
		neighbours.KeepValue(1);
		open_list.AddList(neighbours);

		// If open_list is empty and we have not visited the toTile, there is no path.
		if(open_list.IsEmpty())
			return false;

		// Pick a new curr_tile from open_list
		curr_tile = open_list.Begin();
		open_list.RemoveItem(curr_tile);
		closed_list.AddItem(curr_tile, 0); // add it to close_list so it is not visited again

		// Is the new curr_tile the toTile?
		if(curr_tile == toTile)
			return true;
	}
}

/*static*/ function ChapterShips::WaitForLock(tile)
{
	ChapterShips.WaitFor(GSMarine.IsLockTile, [tile], GSText(GSText.STR_SHIPS_NOTICE_WAITING_FOR_LOCK));
}

/*
 * @param isDoneFunction a function that will tell if the waiting is done. If it
 *    returns boolean true or a value != -1, the waiting is over.
 * @param functionArgsArray a squirrel array containing the arguments to isDoneFunction.
 *    there is maximum argument count which is set by Helper.CallFunction. 
 * @param waitMessage a literal text or GSText instance that contains a message that will
 *    be displayed in a message window when we have been waiting for the user in more than
 *    30 seconds and the user has closed the main timeline message.
 */
/*static*/ function ChapterShips::WaitFor(isDoneFunction, functionArgsArray, waitMessage)
{
	local start_time = GSDate.GetSystemTime();
	local message = false;
	local message_id = 2; // used as uniqueid for GSGoal.Question

	local done_val = Helper.CallFunction(isDoneFunction, functionArgsArray);
	local done = typeof(done_val) == "bool"? done_val : done_val != -1;
	while (!done)
	{
		if(!message && 
				start_time + 30 < GSDate.GetSystemTime() && 
				!GSWindow.IsOpen(GSWindow.WC_GOAL_QUESTION, MSG_WIN_UNIQUE_NUM)) // require the main timeline message to be closed in order to show the notification window
		{
			// The user might not know that we are waiting
			message = GSGoal.Question(message_id, HUMAN_COMPANY, waitMessage, GSGoal.QT_INFORMATION, GSGoal.BUTTON_CLOSE);
		}

		GSController.Sleep(1);

		done_val = Helper.CallFunction(isDoneFunction, functionArgsArray);
		done = typeof(done_val) == "bool"? done_val : done_val != -1;
	}

	// Close the notification about waiting for dock construction if it has been shown
	if(message)
		GSGoal.CloseQuestion(message_id);
}
