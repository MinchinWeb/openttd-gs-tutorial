
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
	main_instance.AddStep(MessageStep("Trains chapter\n\n" +
			"This chapter has not been written yet."));
}

