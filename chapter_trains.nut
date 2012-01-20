
class ChapterTrains {

	constructor() {
	}

	static function LoadChapter(main_instance);
}

/*static*/ function ChapterTrains::LoadChapter(main_instance)
{
	main_instance.AddStep(MessageStep("Trains chapter\n\n" +
			"This chapter has not been written yet."));
}

