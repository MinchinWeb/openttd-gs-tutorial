
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
	}));

	// 2.2 - Ship dock construction (for refinery)
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_1_1), WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		GSViewport.ScrollTo(GSIndustry.GetLocation(table.refinery)); // scroll viewport to the oil refinery
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_1_2), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_MAIN_TOOLBAR, 0, GSWindow.WID_TN_WATER));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_1_3), NO_WAIT));
	main_instance.AddStep(GUIHighlightStep(GSWindow.WC_BUILD_TOOLBAR, 2, GSWindow.WID_DT_STATION, NO_WAIT));
	main_instance.AddStep(CodeStep( function(table) {
		ChapterShips.WaitForDockForIndustry(table.refinery);
		table.refinery_dock <- ChapterShips.GetDockForIndustry(table.refinery);
	}));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_SHIPS_2_1_4), WAIT));

	// 2.2 - Ship depot construction
}

/*static*/ function ChapterShips::WaitForDockForIndustry(industry)
{
	local start_time = GSDate.GetSystemTime();
	local message = false;
	local message_id = 2; // used as uniqueid for GSGoal.Question
	while (ChapterShips.GetDockForIndustry(industry) == -1) // do not use GSStation.IsValidStation here as that will probably need a GSCompanyMode, but GSGoal.Question can't be used when a company mode is active.
	{
		if(!message && 
				start_time + 30 < GSDate.GetSystemTime() && 
				!GSWindow.IsOpen(GSWindow.WC_GOAL_QUESTION, MSG_WIN_UNIQUE_NUM)) // require the main timeline message to be closed in order to show the notification window
		{
			// The user might not know that we are waiting
			message = GSGoal.Question(message_id, HUMAN_COMPANY, GSText(GSText.STR_SHIPS_NOTICE_WAITING_FOR_DOCK_BUILD, industry), GSGoal.QT_INFORMATION, GSGoal.BUTTON_CLOSE);
		}

		GSController.Sleep(1);
	}

	// Close the notification about waiting for dock construction if it has been shown
	if(message)
		GSGoal.CloseQuestion(message_id);
}

/*static*/ function ChapterShips::CoverageDistance(station, tileb)
{
	local tilea = GSStation.GetLocation(station);
	local dx = Helper.Abs(GSMap.GetTileX(tilea) - GSMap.GetTileX(tileb));
	local dy = Helper.Abs(GSMap.GetTileY(tilea) - GSMap.GetTileY(tileb));

	GSLog.Info(dx + ":" + dy);

	return Helper.Max(dx, dy);
}

/*static*/ function ChapterShips::GetDockForIndustry(industry)
{
	local company_mode = GSCompanyMode(HUMAN_COMPANY);
	local st_list = GSStationList(GSStation.STATION_DOCK);

	st_list.Valuate(ChapterShips.CoverageDistance, GSIndustry.GetLocation(industry));
	st_list.RemoveAboveValue(GSStation.GetCoverageRadius(GSStation.STATION_DOCK));

	if(st_list.IsEmpty())
		return -1;

	return st_list.Begin();
}
