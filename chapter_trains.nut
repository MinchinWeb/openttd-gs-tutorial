
class ChapterTrains {

	constructor() {
	}

	static function ID();
	static function LoadChapter(main_instance);
}

/*static*/ function ChapterTrains::ID()
{
	return "trains";
}

/*static*/ function ChapterTrains::LoadChapter(main_instance)
{
	main_instance.AddStep(MessageWindowStep("Trains chapter - TODO", WAIT));
}

