
class ChapterBus {

	constructor() {
	}

	static function LoadBusChapter(main_instance);

	static function FindTownsToConnect();
	static function PopulationValuator(town);
	static function TownDistValuator(town1, town2, target_dist);
	static function GetMenuLocationNearTown(town, other_town);
	static function MenuOtherTownDistanceValuator(tile, other_town_tile);

	static function Error(error);
}

/*static*/ function ChapterBus::LoadBusChapter(main_instance)
{
	main_instance.AddStep(MessageStep("Bus service\n\n" +
			"In this chapter a first transport service will be setup using buses to transport passengers between two towns."));
	main_instance.AddStep(CodeStep(function(table) {

		table.towns <- ChapterBus.FindTownsToConnect();
		if(table.towns[0] == null || table.towns[1] == null)
		{
			g_menu.Close();
			ChapterBus.Error("failed to find two towns to connect");
			return;
		}

		GSSign.BuildSign(GSTown.GetLocation(table.towns[0]), "TOWN A");
		GSSign.BuildSign(GSTown.GetLocation(table.towns[1]), "TOWN B");
} ));
	main_instance.AddStep(MessageStep("The first step is to find two suitable towns. In this tutorial the towns marked with TOWN A and TOWN B signs will be connected.\n\nNext menu will be displayed near Town A"));
	main_instance.AddStep(CodeStep(function(table) {

		local menu_location = ChapterBus.GetMenuLocationNearTown(table.towns[0], table.towns[1]);
		g_menu.SetLocation(menu_location);
		GSViewport.ScrollTo(menu_location);

} ));
	main_instance.AddStep(MessageStep("A bus service needs bus stops where passengers will wait and the buses will stop and pick up the passengers. When you click to continue, you'll get GUI help to build a bus stop."));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_ROADS));
	main_instance.AddStep(CodeStep(function(table){
		while(!GSWindow.IsOpen(GSWindow.WC_BUILD_TOOLBAR, 1)) { 
			GSController.Sleep(1); 
		}
	}));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 1, GSWindow.WID_ROT_BUS_STATION));
	main_instance.AddStep(MessageStep("Now find a tile next to road in Town A. Mind the rotation of the bus station"));

//	main_instance.AddStep(MessageStep("When you click continue, a bus stop will be placed in Town B"));
//	main_instance.AddStep(MessageStep("Now both towns have a bus stop to collect passengers. Next a road has to be built to connect the two towns.\n\nWhen you click on continue a road will be built between the towns. This may take some time."));
}

/*
	GSRoad.SetCurrentRoadType(GSRoad.ROADTYPE_ROAD);

	g_menu_viewer.Open("Bus service\n\n" +
			"In this chapter a first transport service will be setup using buses to transport passengers between two towns.", 
			["continue"])
	g_menu_viewer.WaitUntilClose();


	// Find two towns
	//Helper.SetSign(g_menu_viewer.location, "preparing tutorial ...", true);
	g_menu_viewer.Open("Preparing tutorial...\n(Hold TAB-key to speed up)", []);
	local towns = ChapterBus.FindTownsToConnect();
	if(towns[0] == null || towns[1] == null)
	{
		g_menu_viewer.Close();
		ChapterBus.Error("failed to find two towns to connect");
		return;
	}
	local town_tiles = [GSTown.GetLocation(towns[0]), GSTown.GetLocation(towns[1])];
	
	local road_builder = RoadBuilder();
	road_builder.Init(town_tiles[0], town_tiles[1]);
	if(!road_builder.DoPathfinding())
	{
		// failed to find path between towns
		g_menu_viewer.Close();
		ChapterBus.Error("The bus tutorial failed on this map. Try to create a new game and try again.");
		return;
	}

	g_menu_viewer.Close();

	// Tell user about found towns A + B
	Helper.SetSign(GSTown.GetLocation(towns[0]), "TOWN A", true);
	Helper.SetSign(GSTown.GetLocation(towns[1]), "TOWN B", true);
	g_menu_viewer.Open("The first step is to find two suitable towns. In this tutorial the towns marked with TOWN A and TOWN B signs will be connected.\n\nNext menu will be displayed near Town A",
			["continue"]);
	g_menu_viewer.WaitUntilClose();
	g_menu_viewer.SetLocation(ChapterBus.GetMenuLocationNearTown(towns[0], towns[1]));


	// Build bus stops
	g_menu_viewer.Open("A bus service needs bus stops where passengers will wait and the buses will stop and pick up the passengers. When you click on continue, a bus stop will be placed in Town A.",
			["continue"]);
	g_menu_viewer.WaitUntilClose();

	local station_tiles = [null, null];
	station_tiles[0] = Road.BuildStopInTown(towns[0], GSRoad.ROADVEHTYPE_BUS, Helper.GetPAXCargo(), Helper.GetPAXCargo()); // reduce risk of failing, by accepting locations that doesn't fully accept/produce passengers

	g_menu_viewer.Open("When you click continue, a bus stop will be placed in Town B",
			["continue"]);
	g_menu_viewer.WaitUntilClose();

	station_tiles[1] = Road.BuildStopInTown(towns[1], GSRoad.ROADVEHTYPE_BUS, Helper.GetPAXCargo(), Helper.GetPAXCargo()); // reduce risk of failing, by accepting locations that doesn't fully accept/produce passengers

	if(station_tiles[0] == null || !GSMap.IsValidTile(station_tiles[0]) ||
		station_tiles[1] == null || !GSMap.IsValidTile(station_tiles[1]))
	{
		ChapterBus.Error("failed to build road stop");
		return;
	}

	// Build road
	g_menu_viewer.Open("Now both towns have a bus stop to collect passengers. Next a road has to be built to connect the two towns.\n\nWhen you click on continue a road will be built between the towns. This may take some time.",
			["continue"]);
	g_menu_viewer.WaitUntilClose();

	{
		road_builder.EnableSlowBuilding();
		local ret = road_builder.ConnectTiles();

		if(ret != RoadBuilder.CONNECT_SUCCEEDED)
		{
			ChapterBus.Error("failed to build road");
			return;
		}
	}

	// Build depot
	g_menu_viewer.Open("Now there is both bus stops and a road. Next thing we want is a bus. But in order to buy a bus, a depot is needed.\n\nWhen you click on continue, a depot will be placed in town A",
			["continue"]);
	g_menu_viewer.WaitUntilClose();
	local depot_tile = Road.BuildDepotNextToRoad(station_tiles[0], 50, 10000);

	if(depot_tile == null || !GSMap.IsValidTile(depot_tile))
	{
		ChapterBus.Error("failed to build road stop");
		return;
	}

	// Build bus
	g_menu_viewer.Open("Now all infrastructure is done. The following steps are now to buy a bus, give it orders and release it from the depot.",
			["continue"]);
	g_menu_viewer.WaitUntilClose();

	g_menu_viewer.Open("If you click on the depot you will open a window that shows the contents inside the depot. (now empty, but a bus will soon be built)",
			["continue"]);
	g_menu_viewer.WaitUntilClose();

	local engine = Engine.GetEngine_PAXLink(20, GSVehicle.VT_ROAD);
	if(!GSEngine.IsValidEngine(engine))
	{
		ChapterBus.Error("couldn't find a suitable bus to buy");
		return;
	}
	
	local vehicle = GSVehicle.BuildVehicle(depot_tile, engine);
	if(!GSVehicle.IsValidVehicle(vehicle))
	{
		ChapterBus.Error("couldn't buy bus");
		return;
	}
	GSVehicle.RefitVehicle(vehicle, Helper.GetPAXCargo()); // since GetEngine_PAXLink can return engines that by default don't carry PAX (but can be refitted to PAX), we need to refit bough vehicles to PAX.

	g_menu_viewer.Open("A bus has been built and is now located in the bus depot. Next step is to assign orders to it to visit the two bus stations.\n\nIf you click on the bus and then on the fourth button from the top on the right, you can see the order list.",
			["continue"]);
	g_menu_viewer.WaitUntilClose();

	// Add orders
	local order_list = OrderList();
	order_list.AddStop(GSStation.GetStationID(station_tiles[0]), GSOrder.OF_NONE);
	order_list.AddStop(GSStation.GetStationID(station_tiles[1]), GSOrder.OF_NONE);
	order_list.ApplyToVehicle(vehicle);

	g_menu_viewer.Open("Now everything is ready except for starting the bus. This is done by clicking at the bottom of the vehicle window.",
			["continue"]);
	g_menu_viewer.WaitUntilClose();

	// Start Bus
	GSVehicle.StartStopVehicle(vehicle);

	// Done
	g_menu_viewer.Open("Summary\n\nThe bus chapter has now came to an end and you have seen how to build a bus service between two towns.\n\n" +
			"As an exercise you might want to add another bus or connect two other towns.",
			["continue"]);
	g_menu_viewer.WaitUntilClose();

	// Remove Town A/B etc. signs
	Helper.ClearAllSigns();
}
*/

/* static */ function ChapterBus::Error(error)
{
	g_menu.Open("Tutorial Error: " + error, 
			["continue"])
	g_menu.WaitUntilClose();
}

/* static */ function ChapterBus::PopulationValuator(town)
{
	return Helper.Abs(GSTown.GetPopulation(town) - 400);
}

/* static */ function ChapterBus::MapCenterValuator(town)
{
	local town_loc = GSTown.GetLocation(town);
	local town_x = GSMap.GetTileX(town_loc);
	local town_y = GSMap.GetTileY(town_loc);

	return Helper.Abs( 
			Helper.Abs(GSMap.GetMapSizeX() / 2 - town_x) + Helper.Abs(GSMap.GetMapSizeY() / 2 - town_y) // Gives center of map lowest result
			- 10 // gives towns 10 Manhattan tiles away from center the highest score (so the menu don't cover the town)
		);
}

/* static */ function ChapterBus::TownDistValuator(town_a, town_b, target_dist)
{
	return Helper.Abs(GSMap.DistanceSquare(GSTown.GetLocation(town_a), GSTown.GetLocation(town_b)) - target_dist);
}

/* static */ function ChapterBus::FindTownsToConnect()
{
	local towns = GSTownList();
	towns.Valuate(ChapterBus.MapCenterValuator)
	towns.KeepBottom(1);

	local town1 = towns.Begin();

	Log.Info("Town 1 : " + town1 + " " + GSTown.GetName(town1), Log.LVL_DEBUG);

	towns = GSTownList();
	towns.RemoveItem(town1); // don't connect town1 with town1
	towns.Valuate(ChapterBus.TownDistValuator, town1, 60);
	towns.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);

	if(towns.GetValue(towns.Begin()) < 20*20) // If at least one town is within +/- 20 tiles from the target distance of 60 tiles
	{
		towns.KeepBelowValue(20*20);
	}
	else
	{
		towns.KeepTop(1); // Keep the best town range-wise
	}

	// Out of the towns that fulfill the range-selection, pick the one with best population
	towns.Valuate(ChapterBus.PopulationValuator);
	towns.KeepBottom(1);

	local town2 = towns.Begin();
	Log.Info("Town 2 : " + town2 + " " + GSTown.GetName(town2), Log.LVL_DEBUG);

	return [town1, town2];
}

/* static */ function ChapterBus::MenuOtherTownDistanceValuator(tile, other_town_tile)
{
	local dist = GSMap.DistanceManhattan(tile, other_town_tile);
	if(dist < 9)
	{
		return 100 * dist;
	}

	return dist;
}

/* static */ function ChapterBus::GetMenuLocationNearTown(town, other_town)
{
	local list = GSList();
	local town_tile = GSTown.GetLocation(town);
	local other_town_tile = GSTown.GetLocation(other_town);

	foreach(dir, _ in Direction.GetAllDirsInRandomOrder())
	{
		// Add tile 6 to 10 tiles away in each direction (depending on direction)
		//
		// The menu is displayed from the menu location and south. Thus place it further away
		// if it is placed north of the town.
		local distance = 6;
		if(dir == Direction.DIR_N)
			distance += 4;
		else if(dir == Direction.DIR_NE || dir = Direction.DIR_NW)
			distance += 2
		local tile = Direction.GetTileInDirection(town_tile, dir, distance);
		if(GSMap.IsValidTile(tile))
		{
			list.AddItem(Direction.GetTileInDirection(town_tile, dir, 8), 0);
		}
	}

	// Pick a tile that is not too close to the other town tile.
	// On the other hand, it is not a bad thing if the menu is
	// placed on the way towards the other town if, it is far away.
	list.Valuate(ChapterBus.MenuOtherTownDistanceValuator, other_town_tile);
	list.KeepBottom(1); // keep lowest value

	local tile = list.Begin();
	if(GSMap.IsValidTile(tile))
		return tile;

	return town_tile; // fallback to the town center tile if everything else fails
}
