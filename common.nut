
class Common
{
}

/*
 * parameters:
 *   vehicle = vehicle id
 *   station_array = a squirrel array containing station ids.
 *   waiting_message = a literal string or a GSText instance
 */
/*static*/ function Common::WaitForOrderToStations(vehicle, station_array, waiting_message)
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
			foreach(station_id in station_array)
			{
				local has_station = false;
				for(local i = 0; i < GSOrder.GetOrderCount(vehicle); i++)
				{
					if(GSOrder.IsGotoStationOrder(vehicle, i) &&
							GSStation.GetStationID(GSOrder.GetOrderDestination(vehicle, i)) == station_id)
					{
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
			// The user might not know that we are waiting
			message = GSGoal.Question(message_id, HUMAN_COMPANY, waiting_message, GSGoal.QT_INFORMATION, GSGoal.BUTTON_CLOSE);
		}

		GSController.Sleep(1);
	}

	// Close the notification about waiting for dock construction if it has been shown
	if(message)
		GSGoal.CloseQuestion(message_id);
}
