
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
	main_instance.AddStep(MessageStep("Ships chapter\n\n" +
			"In this chapter a first transport service will be setup using buses to transport passengers between two towns."));
}

