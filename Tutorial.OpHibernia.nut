/*	Operation Hibernia v.4bis, r.256, [2012-08-13]
 *		originally part of WmDOT v.10,
 *		part of Beginner's Tutorail (GameScript) v.8
 *	Copyright © 2011-12 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */
 
/*	This file is provided under the same license as the rest of the Beginner's
 *		Tutorial.
 */
 
/*	Operation Hibernia
 *		Hibernia refers to the oil field and production platform in the North
 *		Atlantic Ocean, about 300km ESE from St. John's, Newfoundland, Canada.
 *		Hibernia is the world's largest oil platform.
 *
 *		Operation Hibernia seeks out oil platforms, and then transports oil to
 *		Oil Refinaries.
 */
 
//	Requires MinchinWeb's MetaLibrary v.5
//	Requires Zuu's SuperLib v.24


class OpHibernia {
	function GetVersion()       { return 4; }
	function GetRevision()		{ return 242; }
	function GetDate()          { return "2012-10-25"; }
	function GetName()          { return "Operation Hibernia (GS)"; }
	
	
	_NextRun = null;
//	_ROI = null;
//	_Cost = null;
	
	_SleepLength = null;	//	as measured in days
	_TransportedCutOff = null;	//	maximum percentage of transported cargo for an industry still to be considered.
	_CapacityDays = null;		//	this is the (max) numbers of days production a ship will be built to transport
	_Atlas = null;
	_AtlasModel = null;
	_Serviced = null;		//	Industries that have already been serviced
	
	Log = null;
	Money = null;
//	Manager_Ships = null;
	
	constructor()
	{
		this._NextRun = 0;
		this._SleepLength = 90;
		this._TransportedCutOff = 50;	// Turn this into an GS setting??
		this._CapacityDays = 60;
		
		this._Atlas = MetaLib.Atlas();
		this._AtlasModel = ModelType.DISTANCE_SHIP;
//		this._AtlasModel = 2;
		this._Atlas.SetModel(this._AtlasModel);
		this._Serviced = [];
		
		Log = OpLog();
		Money = OpMoney();
//		Manager_Ships = ManShips();
	}
}
 
 function OpHibernia::Run(table) {

	local tick = GSController.GetTick();
	mwLog.Note("OpHibernia (GS) running at tick " + tick + ".",1);
	
//	local table = {};
//	ChapterShip.Init(table);
	
//	local cm = GSCompanyMode(HUMAN_COMPANY);	
	
/*	if (GSGameSettings.IsDisabledVehicleType(GSVehicle.VT_WATER) == true) {
		mwLog.Note("** OpHibernia has been disabled. **",0);
		return false;
	}
*/
	local CargoNo = ChapterShips.GetOilCargo();

	//	TO-DO: Add a check here to see if we can actually transport the cargo in question!
	//				SuperLib.Engine.DoesEngineExistForCargo(cargo_id, vehicle_type = -1, no_trams = true, no_articulated = true, only_small_aircrafts = false)
	
	//	Get a list of Oil Rigs, and add those without our ships to the sources list;
	//	Keep only those that are underserviced (less than 25%, typically)
//	local MyIndustries = GSIndustryList();
	local MyIndustries = GSList();
	
	//	Add predefined oil rigs
	MyIndustries.AddItem(table.oilrig1, 0);
	MyIndustries.AddItem(table.oilrig2, 0);
	
	MyIndustries.Valuate(GSIndustry.GetLastMonthTransportedPercentage, CargoNo);
	MyIndustries.KeepBelowValue(this._TransportedCutOff);
	MyIndustries.Valuate(GSIndustry.GetLastMonthProduction, CargoNo);
	MyIndustries.KeepAboveValue(1);
	mwLog.Note("On Cargo: " + GSCargo.GetCargoLabel(CargoNo) + ", " + MyIndustries.Count() + " input Industry kept.", 2);
	
	MyIndustries.Valuate(Helper.ItemValuator);
	this._Atlas.Reset();
	foreach (Location in MyIndustries) {
		///		Priority is the production level
		this._Atlas.AddSource(GSIndustry.GetLocation(Location), ( GSIndustry.GetLastMonthProduction(Location, CargoNo) * ( 100 - GSIndustry.GetLastMonthTransportedPercentage(Location, CargoNo) ) ) / 100);
		mwLog.Note("Atlas.AddSource([" + GSMap.GetTileX(GSIndustry.GetLocation(Location)) + ", " + GSMap.GetTileY(GSIndustry.GetLocation(Location)) + "], " + (GSIndustry.GetLastMonthProduction(Location, CargoNo) * (( 100 - GSIndustry.GetLastMonthTransportedPercentage(Location, CargoNo) ) ) / 100) + ")   (" + GSIndustry.GetName(Location) + ")", 5);
	}	//	end of  foreach (Location in MyIndustries)

	///	Get a list of Oil Refinaries and add to the attraction list; Priority is the goods production level
	this._Atlas.AddAttraction(table.refinery, 1);
	
	///	Apply Traffic Model, and select best pair
	local tick2 = GSController.GetTick();
	this._Atlas.SetModel(this._AtlasModel);
	this._Atlas.RunModel();
	mwLog.Note("Atlas.RunModel() took " + (GSController.GetTick() - tick2) + " ticks.", 2);
	//	TO-DO:	Apply maximum distance, based on ship travel speeds
	
	local KeepTrying = true;
	while (KeepTrying == true) {
		local BuildPair = this._Atlas.Pop();
		if (BuildPair == null) {
			mwLog.Note("No Build Pairs.", 3);
			KeepTrying = false;
		} else {
			mwLog.Note("BuildPair is" + Array.ToStringTiles1D(BuildPair) + "  (" + MetaLib.Industry.GetIndustryID(BuildPair[0]) + ", " + MetaLib.Industry.GetIndustryID(BuildPair[1]) + ")", 3);
			//	Get build location for dock at Oil Refinary
			//	At this point, we know that the first industry has a dock; now we have to figure out what to do about the second industry
			local DockLocation = _MinchinWeb_C_.InvalidTile();
			
			if (GSIndustry.HasDock(MetaLib.Industry.GetIndustryID(BuildPair[1])) == true) {
			//	1. Test if the Industry has a built in dock
				DockLocation = GSIndustry.GetDockLocation(MetaLib.Industry.GetIndustryID(BuildPair[1]));	
			} else {
			//	2. Test if we have a dock built that would work
				mwLog.Note("Max Station Spread is : " + MetaLib.Constants.MaxStationSpread(), 5);
				local MyStations = GSStationList(GSStation.STATION_DOCK);
				mwLog.Note("Start with " + MyStations.Count() + " stations.", 5);
				//	Test stations based on distance to industry
				MyStations.Valuate(GSStation.GetDistanceManhattanToTile, BuildPair[1]);
				MyStations.KeepBelowValue((MetaLib.Constants.MaxStationSpread() + MetaLib.Constants.IndustrySize() + GSStation.GetCoverageRadius(GSStation.STATION_DOCK)) * 2);
				mwLog.Note("Kept " + MyStations.Count() + " stations (close enough).", 5);
				//	Test stations to see if they accept cargo in question
				MyStations.Valuate(MetaLib.Station.IsCargoAccepted, CargoNo);
				MyStations.KeepValue(true.tointeger());
				mwLog.Note("Kept " + MyStations.Count() + " stations.", 3);
						
				if (MyStations.Count() > 0) {
					//	If more than one station, use the closest to other industry
					MyStations.Valuate(GSStation.GetDistanceManhattanToTile, BuildPair[0]);
					MyStations.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);
					local templist = GSTileList_StationType(MyStations.Begin(), GSStation.STATION_DOCK);
					DockLocation = templist.Begin();
				} else {
				//	3. Build a dock
					//	TO-DO: consider using station spread to get a spot (i.e. build a
					//				truck stop to reach the refinery)
					//	TO-DO: wait to build the dock until we are ready to start the route
					//	TO-DO: only build the dock (or pass on it's location) if it is in
					//				the same waterbody as BuildPair[0]
							
					local PossibilitesList = Marine.GetPossibleDockTiles(MetaLib.Industry.GetIndustryID(BuildPair[1]));
					mwLog.Note("Build Possibilites: " + Array.ToStringTiles1D(PossibilitesList, true), 5);
					if (PossibilitesList.len() == 0) {
						mwLog.Note("     No dock possible near" + Array.ToStringTiles1D([BuildPair[1]]) + ".", 3);
						//	Let the routine come up with another pair from the Atlas
					} else {
						Money.FundsRequest((GSMarine.GetBuildCost(GSMarine.BT_DOCK) + GSTile.GetBuildCost(GSTile.BT_CLEAR_GRASS)) * 1.1);
						
						local PossibilitiesGSList = GSTileList();
						for (local i = 0; i < PossibilitesList.len(); i++) {
							PossibilitiesGSList.AddItem(PossibilitesList[i], GSMap.DistanceManhattan(PossibilitesList[i], BuildPair[0]));
						}
						PossibilitiesGSList.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);
						
						local KeepTrying3 = true;
						DockLocation = PossibilitiesGSList.Begin();
						while (KeepTrying3) {
							mwLog.Note("Trying DockLocation =" + Array.ToStringTiles1D([DockLocation]), 5);
//									DockLocation = PossibilitiesGSList.Next();
							if ((GSTile.GetCargoAcceptance(DockLocation, CargoNo, 1, 1, GSStation.GetCoverageRadius(GSStation.STATION_DOCK)) >= 8) && (GSMarine.BuildDock(DockLocation, GSStation.STATION_NEW))) {
								// it worked! We have a dock! Nothing more...
								mwLog.Note("Built Dock at" + Array.ToStringTiles1D([DockLocation]), 3);
								KeepTrying3 = false;
							} else {
								if (PossibilitiesGSList.IsEnd()) {
									DockLocation = MetaLib.Constants.InvalidTile()
									KeepTrying3 = false;
								} else {
									DockLocation = PossibilitiesGSList.Next();
								}
							}
						}	
					}
				}
			}
			
			if (DockLocation == MetaLib.Constants.InvalidTile()) {
				mwLog.Note("No valid dock location.", 3);
				//	probably keep KeepTrying = ture
			} else {
				mwLog.Note("DockLocation is" + Array.ToStringTiles1D([DockLocation]) + ".", 3);
				///	Run Waterbody Check to see if Oil Refinary dock and Oil Rig are connected
				local WBC = MetaLib.WaterbodyCheck();
				local Starts = Marine.GetDockFrontTiles(BuildPair[0]);
				local Ends = Marine.GetDockFrontTiles(DockLocation);
				mwLog.Note("starts: " + Array.ToStringTiles1D(Starts) + "  -> ends: " + Array.ToStringTiles1D(Ends), 5);
				
				//	The Ship Pathfinder can only have one start and one end tile
				local KeepTrying2 = true;
				local start;
				local end;
				local Starts2 = Helper.SquirrelListToGSList(Starts);
				local Ends2 = Helper.SquirrelListToGSList(Ends);
				Starts2.Valuate(Marine.DistanceShip, BuildPair[1]);
				Ends2.Valuate(Marine.DistanceShip, BuildPair[0]);
				Starts2.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);
				Ends2.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);
				local OldStarts2 = Starts2;
				start = Starts2.Begin();
				end = Ends2.Begin();
				tick2 = GSController.GetTick();
				local WBCTries = 0;
				local WBCResults;
					
				while (KeepTrying2 == true) {
					mwLog.Note("WBC:: start: " + Array.ToStringTiles1D([start]) + "  -> end: " + Array.ToStringTiles1D([end]), 5);
					WBC.InitializePath([start], [end]);
					WBC.PresetSafety(start, end);
					WBCResults = WBC.FindPath(-1);
					WBCTries ++;
					if (WBCResults != null) {
						mwLog.Note("Waterbody Check returns positive. Took " + WBCTries + " tries and " + (GSController.GetTick() - tick2) + " ticks.",3);
						KeepTrying2 = false;
					} else if (Starts2.IsEnd()) {
					//	this tree will test all pairs of starts and ends
						if (Ends2.IsEnd()) {
							mwLog.Note("Waterbody Check returns negative. Took " + WBCTries + " tries and " + (GSController.GetTick() - tick2) + " ticks.",3);
							KeepTrying2 = false;
						} else {
							Starts2 = OldStarts2;
							start = Starts2.Begin();
							end = Ends2.Next();
						}
							} else {
								start = Starts2.Next();
							}
						}

				if (WBCResults != null) {
					///	Run Ship Pathfinder, and build buoys
					tick2 = GSController.GetTick();
					local Pathfinder = MetaLib.ShipPathfinder();
					Pathfinder.InitializePath([start], [end]);
					//	Ship Pathfinder must be given a single start tile and a
					//		single end tile
					//	Tell the pathfinder to skip Waterbody Check
					Pathfinder.OverrideWBC();
					local SPFResults = Pathfinder.FindPath(-1);
					
					if (SPFResults != null) {
						mwLog.Note("Ship Pathfinder returns positive. Took " + (GSController.GetTick() - tick2) + " ticks.",3);
						
						//	Build Buoys
						local NumberOfBuoys = Pathfinder.CountPathBuoys();
						mwLog.Note(NumberOfBuoys + " buoys may be needed.", 5);
						
						//	request funds for Buoys
						//	request funds for Depots
						Money.FundsRequest((GSMarine.GetBuildCost(GSMarine.BT_BUOY) * NumberOfBuoys) + (GSMarine.GetBuildCost(GSMarine.BT_DEPOT) * 2));
						Pathfinder.BuildPathBuoys();
						SPFResults = Pathfinder.GetPath();
						
						//	Build Depots						
						local Depot1 = Marine.BuildDepot(start, MetaLib.Extras.NextCardinalTile(BuildPair[0], BuildPair[1]));
						local Depot2 = Marine.BuildDepot(end, MetaLib.Extras.NextCardinalTile(BuildPair[1], BuildPair[0]));
						mwLog.Note("Depots at" + Array.ToStringTiles1D([Depot1, Depot2]), 4);
						
						//	TO-DO:	Do something if neither depot could be built
						//	TO-DO:	Build Depots in the middle if the path is extra long
						if ((Depot1 == null) && (Depot2 != null)) {
							Depot1 = Depot2;
						}
						
						//	Pick an engine (ship)
						//	TO-DO: More sophisicated engine selection; weight all the factors at once
						local Engines = GSEngineList(GSVehicle.VT_WATER);
						mwLog.Note("Start with " + Engines.Count() + " engines.", 5);
						
						//	Keep only buildable engines
						Engines.Valuate(GSEngine.IsBuildable);
						Engines.KeepValue(true.tointeger());
						mwLog.Note("Only " + Engines.Count() + " are buildable.", 5);
						
						//	TO-DO:	Keep only engines we can afford  -  GSEngine.GetPrice(EngineID)
						
						//	Keep only ships for this cargo
						Engines.Valuate(GSEngine.CanRefitCargo, CargoNo);
						Engines.KeepValue(true.tointeger());
						mwLog.Note("Only " + Engines.Count() + " can carry " + GSCargo.GetCargoLabel(CargoNo) + ".", 5);
						
						//	Keep only ships under max capacity
						//		"In case it can transport multiple cargoes, it returns the first/main."
						local MaxCargo = (GSIndustry.GetLastMonthProduction(MetaLib.Industry.GetIndustryID(BuildPair[0]), CargoNo) * this._CapacityDays)/30;
						Engines.Valuate(GSEngine.GetCapacity);
						Engines.RemoveAboveValue(MaxCargo);
						mwLog.Note("Only " + Engines.Count() + " have capacity below " + MaxCargo + ". (" + GSIndustry.GetLastMonthProduction(MetaLib.Industry.GetIndustryID(BuildPair[0]), CargoNo) + " * " + this._CapacityDays + " / 30)", 5);
						
						//	Pick the best rated one
						Marine.RateShips(1, 40, 0);
						Engines.Valuate(Marine.RateShips, 40, CargoNo);
						Engines.Sort(GSList.SORT_BY_VALUE, GSList.SORT_DESCENDING);
								
						if (Engines.Count() > 0) {
							local PickedEngine = Engines.Begin();
							mwLog.Note("Picked engine: " + PickedEngine + " : " + GSEngine.GetName(PickedEngine), 3);

							//	request funds for Ship
							//	TO-DO: Provide for retrofit costs
							Money.FundsRequest(GSEngine.GetPrice(PickedEngine) * 1.1);
							//	Build Ship and give it orders
							local MyVehicle = GSVehicle.BuildVehicle(Depot1, PickedEngine);
							if (GSVehicle.IsValidVehicle(MyVehicle)) {
								GSVehicle.RefitVehicle(MyVehicle, CargoNo);
								mwLog.Note("Added Vehicle № " + MyVehicle + ".", 4);
										
								///	Give Orders!
								//	start station; full load here
								GSOrder.AppendOrder(MyVehicle, GSIndustry.GetDockLocation(MetaLib.Industry.GetIndustryID(BuildPair[0])), GSOrder.OF_FULL_LOAD);
								mwLog.Note("Order (Start): " + MyVehicle + " : " + Array.ToStringTiles1D([GSIndustry.GetDockLocation(MetaLib.Industry.GetIndustryID(BuildPair[0]))]) + ".", 5);
								//	buoys
								for (local i = 0; i < SPFResults.len(); i++) {
									GSOrder.AppendOrder(MyVehicle, SPFResults[i], GSOrder.OF_NONE);
									mwLog.Note("Order: " + MyVehicle + " : " + Array.ToStringTiles1D([SPFResults[i]]) + ".", 5);
								}
								//	end station
								GSOrder.AppendOrder(MyVehicle, DockLocation, GSOrder.OF_NONE);
								mwLog.Note("Order (End): " + MyVehicle + " : " + Array.ToStringTiles1D([DockLocation]) + ".", 5);
								//	buoys, but backwards
								for (local i = SPFResults.len() - 1; i >= 0; i--) {
									GSOrder.AppendOrder(MyVehicle, SPFResults[i], GSOrder.OF_NONE);
									mwLog.Note("Order: " + MyVehicle + " : " + Array.ToStringTiles1D([SPFResults[i]]) + ".", 5);
								}
								
								// send it on it's merry way!!!
								GSVehicle.StartStopVehicle(MyVehicle);
								
								///	Build one ship on path, and turn over to Ship Route Manager
								// Manager_Ships.AddRoute(MyVehicle, CargoNo);		
							}

						} else {
							mwLog.Note("No engine matches criteria.", 3);
						}
						
					} else {
						mwLog.Note("Ship Pathfinder returns negative. Took " + (GSController.GetTick() - tick2) + " ticks.",3);
					}
							
					KeepTrying = false;
				} else {
					mwLog.Note("Waterbody Check returns negative. Took " + (GSController.GetTick() - tick2) + " ticks.",3);
					// try another path
					KeepTrying = true;
				}
			}
		}
	}

	mwLog.Note("OpHibernia finished. Took " + (GSController.GetTick() - tick) + " ticks.", 2);
	
	return true;
}