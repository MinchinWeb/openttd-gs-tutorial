
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
	main_instance.AddStep(MessageWindowStep("Ships chapter - TODO", WAIT));
}

