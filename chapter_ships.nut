
class ChapterShips {

	constructor() {
	}

	static function ID();
	static function LoadChapter(main_instance);

	/* This function is called by the main instance if a later chapter requires that this
	 * chapter needs to be completed and the user have not completed it yet.
	 */
	static function CompleteByAI();
}

/*static*/ function ChapterShips::ID()
{
	return "ships";
}

// The initialization of this chapter have been broken out to an Init-function such that it
// can be shared by LoadChapter and CompleteByAI.
/*static*/ function ChapterShips::Init(table)
{
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
}

/*static*/ function ChapterShips::LoadChapter(main_instance)
{
	// Initialization code
	main_instance.AddStep(CodeStep(ChapterShips.Init));

	// 2.1 - Ship dock construction (for refinery)
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_1_1), WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		GSViewport.ScrollTo(GSIndustry.GetLocation(table.refinery)); // scroll viewport to the oil refinery
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_1_2), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_WATER));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_BUILD_TOOLBAR, 2, WAIT_ON_OPEN));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_1_3), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 2, GSWindow.WID_DT_STATION, NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		// todo: make WaitForDockForIndustry allow docks that doesn't cover top tile of industry.
		ChapterShips.WaitForDockForIndustry(table.refinery);
		table.refinery_dock <- ChapterShips.GetDockForIndustry(table.refinery);
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_1_4), WAIT));

	//main_instance.AddStep(CloseMessageWindowStep()); // close message if user didn't close it
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_STATION, 2)); // close windows from dock construction
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_TOOLBAR, 2)); 

	// 2.2 - Ship depot construction
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_2_1), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_WATER));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_BUILD_TOOLBAR, 2, WAIT_ON_OPEN));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 2, GSWindow.WID_DT_DEPOT, WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_2_2), NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		ChapterShips.WaitForShipyard();
		table.shipyard <- ChapterShips.GetShipyard();
	}));

	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_STATION, 2)); // close windows from shipyard construction
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_TOOLBAR, 2)); 

	// 2.3 - Buying a ship and giving it orders
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_3_1), NO_WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_VEHICLE_DEPOT, TableKey("shipyard"), WAIT_ON_OPEN)); // while there is no text guidance in this chapter, provide highlights.
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_DEPOT, TableKey("shipyard"), GSWindow.WID_D_BUILD, WAIT));
	//main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_VEHICLE, TableKey("shipyard"), GSWindow.WID_BV_LIST, NO_WAIT)); // no click is required
	main_instance.AddStep(CodeStep( function(table) { // wait a short while
		GSController.Sleep(8);
	}));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_VEHICLE, TableKey("shipyard"), GSWindow.WID_BV_BUILD, NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		ChapterShips.WaitForOilShip();
		table.ship1 <- Common.GetVehicle(GSVehicle.VT_WATER, ChapterShips.GetOilCargo());
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_3_2), WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		local station_loc = GSIndustry.GetDockLocation(table.oilrig1);
		GSViewport.ScrollTo(GSIndustry.GetLocation(table.oilrig1)); // scroll viewport to the oilrig
		GSController.Sleep(25); // sleep a short while
		GSSign.BuildSign(station_loc, GSText(GSText.STR_SHIPS_SIGN_OILRIG_STATION)); // put a sign ontop of the station tile
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_3_3), NO_WAIT, TableKey("oilrig1_station"), TableKey("refinery_dock")));
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
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_4_1), NO_WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_VEHICLE_VIEW, TableKey("ship1"), WAIT_ON_OPEN)); // ensure that the vehicle window is open before waiting for click on start/stop button
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_VIEW, TableKey("ship1"), GSWindow.WID_VV_START_STOP, WAIT)); 
	main_instance.AddStep(CodeStep( function(table) {
		ChapterShips.WaitForShipLeavingOilrigSecondTime(table);
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_4_2), NO_WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_VEHICLE_VIEW, TableKey("ship1"), WAIT_ON_OPEN)); // ensure that the vehicle window is open before waiting for click
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_VIEW, TableKey("ship1"), GSWindow.WID_VV_SHOW_DETAILS, WAIT)); 
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_4_3), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_VIEW, TableKey("ship1"), GSWindow.WID_VV_SHOW_ORDERS, WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_4_4), NO_WAIT, TableKey("oilrig1_station"))); // click on oil rig order
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_ORDERS, TableKey("ship1"), GSWindow.WID_O_ORDER_LIST, WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_4_5), WAIT)); // inform about buttons at bottom
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_4_6), NO_WAIT)); // ask to click on full load any cargo
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_ORDERS, TableKey("ship1"), GSWindow.WID_O_FULL_LOAD, WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_4_7), WAIT)); // inform user what happened

	// 2.5 - canals
	main_instance.AddStep(CodeStep( function(table) {
		// Place signs where the canal should start/end
		Helper.SetSign(table.canal_start_tile, GSText(GSText.STR_SHIPS_SIGN_CANAL_START));
		Helper.SetSign(table.canal_end_tile, GSText(GSText.STR_SHIPS_SIGN_CANAL_END));
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_5_1), WAIT)); // intro to canals
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_5_2), NO_WAIT)); // select canal tool
	main_instance.AddStep(ConditionalStep(function(table) { return !GSWindow.IsOpen(GSWindow.WC_BUILD_TOOLBAR, 2); }, // highlight button to open water toolbar if it is not already open
		GUIHighlightStep(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_WATER, WAIT)));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_BUILD_TOOLBAR, 2, WAIT_ON_OPEN));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 2, GSWindow.WID_DT_CANAL, WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_5_3), NO_WAIT)); // connect highlighted tiles
	// todo: detect that the two tiles are connected with canal tiles
	main_instance.AddStep(CodeStep( function(table) {
		// wait on canal to be built
		ChapterShips.WaitForCanal(table.canal_start_tile, table.canal_end_tile);

		// remove canal signs
		Helper.SetSign(table.canal_start_tile, "");
		Helper.SetSign(table.canal_end_tile, "");
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_5_4), NO_WAIT)); // lock tool
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 2, GSWindow.WID_DT_LOCK, WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		// put signs at the lock tiles
		Helper.SetSign(table.canal_lock1, GSText(GSText.STR_SHIPS_SIGN_LOCK1));
		Helper.SetSign(table.canal_lock2, GSText(GSText.STR_SHIPS_SIGN_LOCK2));
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_5_5), NO_WAIT)); // place lock
	main_instance.AddStep(CodeStep( function(table) {
		// wait for locks
		ChapterShips.WaitForLock(table.canal_lock1);
		ChapterShips.WaitForLock(table.canal_lock2);

		// remove lock signs
		Helper.SetSign(table.canal_lock1, "");
		Helper.SetSign(table.canal_lock2, "");
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_5_6), WAIT)); // summary of canals

	// 2.6 - end of this chapter
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_3_6_1), WAIT));
}

/*static*/ function ChapterShips::WaitForDockForIndustry(industry)
{
	Common.WaitFor(ChapterShips.GetDockForIndustry, [industry], GSText(GSText.STR_SHIPS_NOTICE_WAITING_FOR_DOCK_BUILD, industry));
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
	Common.WaitFor(ChapterShips.GetShipyard, [], GSText(GSText.STR_SHIPS_NOTICE_WAITING_FOR_SHIP_YARD_BUILD));
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
	Common.WaitFor(Common.GetVehicle, [GSVehicle.VT_WATER, ChapterShips.GetOilCargo()], GSText(GSText.STR_SHIPS_NOTICE_WAITING_FOR_OIL_SHIP));
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
	Log.Info(" connection? : " + Tile.CanWalk4ToTile(fromTile, toTile, GSMarine.IsCanalTile));
	Common.WaitFor(Tile.CanWalk4ToTile, [fromTile, toTile, GSMarine.IsCanalTile], GSText(GSText.STR_SHIPS_NOTICE_WAITING_FOR_CANAL));
}

/*static*/ function ChapterShips::WaitForLock(tile)
{
	Common.WaitFor(GSMarine.IsLockTile, [tile], GSText(GSText.STR_SHIPS_NOTICE_WAITING_FOR_LOCK));
}


/*static*/ function ChapterShips::CompleteByAI()
{
	local table = {};
	ChapterShips.Init(table);

	local cm = GSCompanyMode(HUMAN_COMPANY);

	// TODO: Add code to complete chapter

	return true; // allow testing of ships chapter before AI have been implemented
	return false; // todo: return true when it works
}
