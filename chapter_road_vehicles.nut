
class ChapterRoadVehicles {

	constructor() {
	}

	static function LoadChapter(main_instance);
}

/*static*/ function ChapterRoadVehicles::LoadChapter(main_instance)
{
	main_instance.AddStep(MessageStep("RoadVehicles chapter\n\n" +
			"In this chapter a first transport service will be setup using buses to transport passengers between two towns."));
}

