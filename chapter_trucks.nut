
class ChapterTrucks {

	constructor() {
	}

	static function ID();
	static function LoadChapter(main_instance);
}

/*static*/ function ChapterTrucks::ID()
{
	return "trucks";
}

/*static*/ function ChapterTrucks::LoadChapter(main_instance)
{
	main_instance.AddStep(MessageWindowStep("Trucks chapter - TODO", WAIT));
}

