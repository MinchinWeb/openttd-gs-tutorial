
/* cargo constants for default industries */
CARGO_GOODS <- 5;

class Common
{
}


/*
 * parameters:
 *   vehicle = vehicle id
 *   station_array = a squirrel array containing station ids.
 *   waiting_message = a literal string or a GSText instance
 *   require_full_load_at_first = if true, the function will additionally require that the first station have the order flag to full load there.
 */
/*static*/ function Common::WaitForOrderToStations(vehicle, station_array, waiting_message, require_full_load_at_first = false)
{
	local company_mode = GSCompanyMode(HUMAN_COMPANY);
	local message = false;
	local message_id = 2;
	local last_order_count = 0;
	local last_order_count_change = GSDate.GetSystemTime();
	while(true)
	{
		// Have the order count changed?
		if(GSOrder.GetOrderCount(vehicle) != last_order_count)
		{
			// reset timer to detect possible clueless user
			last_order_count_change = GSDate.GetSystemTime();

			// Does the company have all stations?
			local have_all_stations = true;
			local require_full_load = require_full_load_at_first;
			foreach(station_id in station_array)
			{
				local has_station = false;
				for(local i = 0; i < GSOrder.GetOrderCount(vehicle); i++)
				{
					if(GSOrder.IsGotoStationOrder(vehicle, i) &&
							GSStation.GetStationID(GSOrder.GetOrderDestination(vehicle, i)) == station_id)
					{
						// Must this station have the full load (any) order set?
						if(require_full_load)
						{
							local flags = GSOrder.GetOrderFlags(vehicle, i);
							local have_full_load_order = (flags & GSOrder.OF_FULL_LOAD_ANY) != 0 ||
								(flags & GSOrder.OF_FULL_LOAD) != 0;

							if(!have_full_load_order)
								continue;
						}

						has_station = true;
						break;
					}
				}

				// If at least one station is missing, the company doesn't have all.
				if(!has_station)
				{
					have_all_stations = false;
					break;
				}

				// Full load is only (maybe) required at
				// first station.
				require_full_load = false;
			}

			// All stations?
			if(have_all_stations)
				break; // => Stop waiting
		}

		// Show notice if user is slow
		if(!message && 
				last_order_count_change + 60 * 2 < GSDate.GetSystemTime() && 
				!GSWindow.IsOpen(GSWindow.WC_GOAL_QUESTION, MSG_WIN_UNIQUE_NUM)) // require the main timeline message to be closed in order to show the notification window
		{
			company_mode = null;

			// The user might not know that we are waiting
			message = GSGoal.Question(message_id, HUMAN_COMPANY, waiting_message, GSGoal.QT_INFORMATION, GSGoal.BUTTON_CLOSE);

			company_mode = GSCompanyMode(HUMAN_COMPANY);
		}

		GSController.Sleep(1);
	}

	// Close the notification about waiting for dock construction if it has been shown
	if(message)
		GSGoal.CloseQuestion(message_id);
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
/*static*/ function Common::WaitFor(isDoneFunction, functionArgsArray, waitMessage)
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

/*static*/ function Common::GetStationInTown(town, station_type, accept_cargo = -1, produce_cargo = -1)
{
	local company_mode = GSCompanyMode(HUMAN_COMPANY);
	local st_list = GSStationList(station_type);

	st_list.Valuate(GSStation.GetNearestTown);
	st_list.KeepValue(town);

	if(accept_cargo != -1)
	{
		st_list.Valuate(Station.IsCargoAccepted, accept_cargo);
		st_list.KeepValue(1);
	}
	if(produce_cargo != -1)
	{
		st_list.Valuate(Station.IsCargoSupplied, produce_cargo);
		st_list.KeepValue(1);
	}

	if(!st_list.IsEmpty())
	{
		return st_list.Begin();
	}

	return -1;
}

// Warning: Supply at least a accept_cargo or produce_cargo for the function to work!
/*static*/ function Common::GetStationForIndustry(industry, station_type, accept_cargo = -1, produce_cargo = -1)
{
	local company_mode = GSCompanyMode(HUMAN_COMPANY);
	local st_list = GSStationList(station_type);

	if(accept_cargo != -1)
	{
		st_list.Valuate(Station.IsCargoAcceptedByIndustry, accept_cargo, industry);
		st_list.KeepValue(1);
	}
	if(produce_cargo != -1)
	{
		st_list.Valuate(Station.IsCargoSuppliedByIndustry, produce_cargo, industry);
		st_list.KeepValue(1);
	}

	if(!st_list.IsEmpty())
	{
		return st_list.Begin();
	}

	return -1;
}

/*
 * vehicle_type = GSVehicle.VehicleType (VT_ROAD etc.)
 * cargo = cargo type
 * black_list = a squirrel array with vehicles to ignore (optional parameter)
 */
/*static*/ function Common::GetVehicle(vehicle_type, cargo, black_list = [])
{
	local company_mode = GSCompanyMode(HUMAN_COMPANY);
	local veh_list = GSVehicleList();
	veh_list.Valuate(GSVehicle.GetVehicleType);
	veh_list.KeepValue(vehicle_type);
	veh_list.Valuate(Vehicle.GetVehicleCargoType);
	veh_list.KeepValue(cargo);

	black_list = Helper.SquirrelListToAIList(black_list);
	veh_list.RemoveList(black_list);

	if(veh_list.IsEmpty())
		return -1;

	return veh_list.Begin();
}

/*static*/ function Common::VehicleStarted_WaitCondition(vehicle_id)
{
	if (GSVehicle.GetState(vehicle_id) != GSVehicle.VS_STOPPED &&
			!GSVehicle.IsStoppedInDepot(vehicle_id))
		return 1;
	else
		return -1; // a wait condition function should return -1 as long as the condition have not been satisfied.
}
