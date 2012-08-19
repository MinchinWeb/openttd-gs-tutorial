
class ChapterTrucks {

	constructor() {
	}

	static function ID();
	static function LoadChapter(main_instance);
}

/*static*/ function ChapterTrucks::ID()
{
	return "trucks";
}

/*static*/ function ChapterTrucks::LoadChapter(main_instance)
{
	// Initialization code
	main_instance.AddStep(CodeStep( function(table) {

		// Source industry = industry index 0 (same refinery as in ship chapter)
		table.refinery <- 0;

		// Dest town:
		table.dest_town <- 10; //2; // highland hills

		table.oil_rig <- 1; // oil rig used by ship chapter
	}));

	// 3.1 - Introduction
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_1_1_INTRO), WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		GSViewport.ScrollTo(GSIndustry.GetLocation(table.oil_rig)); // scroll viewport to oil rig
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_1_2_CHAINS_OPEN), NO_WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_INDUSTRY_VIEW, TableKey("oil_rig"), WAIT_ON_OPEN));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_1_3_CHAINS_OPEN_2), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_INDUSTRY_VIEW, TableKey("oil_rig"), GSWindow.WID_IV_DISPLAY, WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_INDUSTRY_CARGOES, 0, WAIT_ON_OPEN)); // wait on industry chain window
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_1_4_CHAINS_INFO), NO_WAIT)); // ask to click on refinery
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_INDUSTRY_CARGOES, 0, GSWindow.WID_IC_PANEL, WAIT)); // highlight of whole panel
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_1_5_CHAINS_INFO_2), NO_WAIT)); 
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_INDUSTRY_CARGOES, 0, WAIT_ON_CLOSE));
	main_instance.AddStep(CodeStep( function(table) {
		GSViewport.ScrollTo(GSIndustry.GetLocation(table.refinery)); // scroll viewport to refinery
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_1_6_FROM_REFINERY), WAIT)); 
	main_instance.AddStep(CodeStep( function(table) {
		GSViewport.ScrollTo(GSTown.GetLocation(table.dest_town)); // scroll viewport to town
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_1_7_TO_THIS_TOWN), WAIT)); 

	// 4.2 - Building Stations (for town)
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_2_1_BUILD_STATIONS_INFO), NO_WAIT)); 
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_ROADS, NO_WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_BUILD_TOOLBAR, 1, WAIT_ON_OPEN));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_2_2_BUILD_TRUCK_STATION), NO_WAIT)); 
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 1, GSWindow.WID_ROT_TRUCK_STATION, NO_WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_TRUCK_STATION, 1, WAIT_ON_OPEN));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_TRUCK_STATION, 1, GSWindow.WID_BROS_STATION_X, NO_WAIT)); // highlight dtrs
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_TRUCK_STATION, 1, GSWindow.WID_BROS_STATION_Y, NO_WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_2_3_BUILD_ON_TOP), NO_WAIT, TableKey("dest_town"))); 
	main_instance.AddStep(CodeStep( function(table) {
		//<wait for the user to build a station in town, and make sure it accepts goods; if the station does not accept goods, tell the user to try again, and possibly remove the old station>
		ChapterTrucks.WaitForTruckStopInTown(table.dest_town);
		table.town_station_id <- Common.GetStationInTown(table.dest_town, GSStation.STATION_TRUCK_STOP, CARGO_GOODS, -1);
	}));
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_STATION, 1)); // close windows from truck stop construction
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_TOOLBAR, 1)); 

	// 4.3 - Oil Refinery Station
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_3_1_OIL_REFINERY_STATION), NO_WAIT)); 
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_ROADS, NO_WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_BUILD_TOOLBAR, 1, WAIT_ON_OPEN));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_2_2_BUILD_TRUCK_STATION), NO_WAIT)); 
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 1, GSWindow.WID_ROT_TRUCK_STATION, NO_WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_TRUCK_STATION, 1, WAIT_ON_OPEN));
	main_instance.AddStep(CodeStep( function(table) {
		//<wait for the user to build a truck station next to the Oil Refinery that will allow the pick up of goods>
		ChapterTrucks.WaitForTruckStopAtRefinery(table.refinery);
		table.refinery_station_id <- Common.GetStationForIndustry(table.refinery, GSStation.STATION_TRUCK_STOP, -1, CARGO_GOODS);
	}));
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_STATION, 1)); // close windows from truck stop construction
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_TOOLBAR, 1)); 


	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_4_1_ROAD_INFO), NO_WAIT)); 
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_ROADS, NO_WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_BUILD_TOOLBAR, 1, WAIT_ON_OPEN));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_4_2_AUTO_ROAD), NO_WAIT)); 
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 1, GSWindow.WID_ROT_AUTOROAD, WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_4_3_CONNECT_ROAD), NO_WAIT)); 
	main_instance.AddStep(CodeStep( function(table) {
		// <wait until the user builds a road linking the two stations>
		ChapterTrucks.WaitForStationsToBeConnected(table.town_station_id, table.refinery_station_id);
	}));
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_STATION, 1)); // close windows from road construction

	// 3.5 - Depot Construction
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_5_1_ROAD_DEPOT), NO_WAIT)); 
	// todo: highlight road toolbar btn in main toolbar if it is closed
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_BUILD_TOOLBAR, 1, WAIT_ON_OPEN)); 
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 1, GSWindow.WID_ROT_DEPOT, NO_WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_BUILD_DEPOT, 1, WAIT_ON_OPEN)); 
	main_instance.AddStep(CodeStep( function(table) {
		//<wait for the road depot to be connected to both stations>
		Common.WaitFor(ChapterTrucks.GetConnectedDepotAtStation, [table.refinery_station_id], GSText(GSText.STR_TRUCKS_NOTICE_WAITING_FOR_DEPOT, table.refinery_station_id));
		table.depot <- ChapterTrucks.GetConnectedDepotAtStation(table.refinery_station_id);

		// Put a sign on the depot. The player might have placed several depots, so signalize which one
		// that the Tutorial have found.
		Helper.SetSign(table.depot, GSText(GSText.STR_TRUCKS_SIGN_DEPOT));
	}));


	// 3.6 - Vehicles and Orders

	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_6_1_VEHICLES_INFO), NO_WAIT)); 
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_VEHICLE_DEPOT, TableKey("depot"), WAIT_ON_OPEN)); 
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_6_2_BUILD_VEHICLE), NO_WAIT)); 
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_DEPOT, TableKey("depot"), GSWindow.WID_D_BUILD, NO_WAIT));
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_BUILD_VEHICLE, TableKey("depot"), WAIT_ON_OPEN)); 
	main_instance.AddStep(CodeStep( function(table) {
		// find the engine ID of a goods truck to recommend
		local cm = GSCompanyMode(HUMAN_COMPANY);
		local engines = GSEngineList(GSVehicle.VT_ROAD);
		engines.Valuate(GSEngine.GetRoadType);
		engines.KeepValue(GSRoad.ROADTYPE_ROAD);
		engines.Valuate(GSEngine.CanRefitCargo, CARGO_GOODS);
		engines.KeepValue(1);
		table.engine <- engines.Begin();
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_6_3_BUILD_TRUCK), NO_WAIT, TableKey("engine"))); 
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_VEHICLE, TableKey("depot"), GSWindow.WID_BV_LIST, NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) { // wait a short while
		GSController.Sleep(8);
	}));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_VEHICLE, TableKey("depot"), GSWindow.WID_BV_BUILD, NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		// wait on goods truck:
		Common.WaitFor(Common.GetVehicle, [GSVehicle.VT_ROAD, CARGO_GOODS], GSText(GSText.STR_TRUCKS_NOTICE_WAITING_FOR_BUILD_VEHICLE));
		table.truck <- Common.GetVehicle(GSVehicle.VT_ROAD, CARGO_GOODS);
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_6_4_ORDERS), NO_WAIT)); 
	main_instance.AddStep(CodeStep( function(table) {
		local require_full_load_at_first = true;
		Common.WaitForOrderToStations(table.truck, [table.refinery_station_id, table.town_station_id], GSText(GSText.STR_TRUCKS_NOTICE_WAITING_FOR_ORDERS, table.truck, table.refinery_station_id, table.town_station_id), require_full_load_at_first);
	}));

	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_6_5_START_TRUCK), NO_WAIT)); 
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_VIEW, TableKey("depot"), GSWindow.WID_VV_START_STOP, NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		Common.WaitFor(Common.VehicleStarted_WaitCondition, [table.truck], GSText(GSText.STR_TRUCKS_NOTICE_WAITING_FOR_VEH_START, table.truck));
	}));
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_BUILD_VEHICLE, TableKey("depot"))); // close depot windows
	main_instance.AddStep(CloseWindowStep(GSWindow.WC_VEHICLE_DEPOT, TableKey("depot"))); 
	

	// 4.7 - Cloning
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_7_1_CLONING_INFO), NO_WAIT)); 
	main_instance.AddStep(WaitOnWindowStep(GSWindow.WC_VEHICLE_DEPOT, TableKey("depot"), WAIT_ON_OPEN)); 
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_7_2_CLONE_BTN), NO_WAIT)); 
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_VEHICLE_DEPOT, TableKey("depot"), GSWindow.WID_D_CLONE, WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_7_3_CLICK_VEHICLE), NO_WAIT)); 
	main_instance.AddStep(CodeStep( function(table) {
		// wait on cloned truck
		local black_list = [table.truck];
		Common.WaitFor(Common.GetVehicle, [GSVehicle.VT_ROAD, CARGO_GOODS, black_list], GSText(GSText.STR_TRUCKS_NOTICE_WAITING_FOR_CLONE_VEHICLE));
		table.cloned_truck <- Common.GetVehicle(GSVehicle.VT_ROAD, CARGO_GOODS, black_list);
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_7_4_START_CLONE), NO_WAIT)); // ask to start
	main_instance.AddStep(CodeStep( function(table) {
		// wait on start
		Common.WaitFor(Common.VehicleStarted_WaitCondition, [table.cloned_truck], GSText(GSText.STR_TRUCKS_NOTICE_WAITING_FOR_VEH_START, table.cloned_truck));
	}));

	// 4.8 - Conclusion
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_TRUCKS_4_8_1_CONCLUSION), WAIT)); 
}

/*static*/ function ChapterTrucks::WaitForTruckStopInTown(town)
{
	Common.WaitFor(Common.GetStationInTown, [town, GSStation.STATION_TRUCK_STOP, CARGO_GOODS, -1], GSText(GSText.STR_TRUCKS_NOTICE_WAITING_FOR_TOWN_BUILD, town));
}

/*static*/ function ChapterTrucks::WaitForTruckStopAtRefinery(industry)
{
	Common.WaitFor(Common.GetStationForIndustry, [industry, GSStation.STATION_TRUCK_STOP, -1, CARGO_GOODS], GSText(GSText.STR_TRUCKS_NOTICE_WAITING_FOR_REFINERY_BUILD, industry));
}

/*static*/ function ChapterTrucks::WaitForStationsToBeConnected(station1_id, station2_id)
{
	local st1_tiles = GSTileList_StationType(station1_id, GSStation.STATION_TRUCK_STOP);
	local tile1 = st1_tiles.Begin();
	local st2_tiles = GSTileList_StationType(station2_id, GSStation.STATION_TRUCK_STOP);
	local tile2 = st2_tiles.Begin();

	GSRoad.SetCurrentRoadType(GSRoad.ROADTYPE_ROAD);
	Common.WaitFor(Road.AreDistantRoadTilesConnected, [tile1, tile2], GSText(GSText.STR_TRUCKS_NOTICE_WAITING_FOR_CONNECT_ROAD, station1_id, station2_id));
}

/*static*/ function ChapterTrucks::GetConnectedDepotAtStation(station_id)
{
	local cm = GSCompanyMode(HUMAN_COMPANY);
	GSRoad.SetCurrentRoadType(GSRoad.ROADTYPE_ROAD);

	// Get tiles to search
	local tiles = GSTileList_StationType(station_id, GSStation.STATION_TRUCK_STOP);
	tiles = Tile.GrowTileRect(tiles, 10);

	// Filter tiles for a depot owned by human company
	tiles.Valuate(GSRoad.IsRoadDepotTile);
	tiles.KeepValue(1);

	tiles.Valuate(GSTile.GetOwner);
	tiles.KeepValue(HUMAN_COMPANY);

	// No depot?
	if(tiles.IsEmpty()) 
	{
		return -1;
	}

	// Get station tile
	local st_tiles = GSTileList_StationType(station_id, GSStation.STATION_TRUCK_STOP);
	local st_tile = st_tiles.Begin();

	// Pick a depot
	foreach(depot_tile, _ in tiles)
	{
		if(Road.AreDistantRoadTilesConnected(depot_tile, st_tile))
		{
			// There is a road from the depot to the station
			return depot_tile;
		}
	}

	// No connected depot found
	return -1;
}

