
class ChapterBuses {

	constructor() {
	}

	static function ID();
	static function LoadChapter(main_instance);
}

/*static*/ function ChapterBuses::ID()
{
	return "buses";
}

/*static*/ function ChapterBuses::LoadChapter(main_instance)
{
	main_instance.AddStep(MessageWindowStep("Buses chapter - TODO", WAIT));
}

