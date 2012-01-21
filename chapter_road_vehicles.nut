
class ChapterRoadVehicles {

	constructor() {
	}

	static function ID();
	static function LoadChapter(main_instance);
}

/*static*/ function ChapterRoadVehicles::ID()
{
	return "road vehicles";
}

/*static*/ function ChapterRoadVehicles::LoadChapter(main_instance)
{
	main_instance.AddStep(MessageWindowStep("RoadVehicles chapter - TODO", WAIT));
}

