
class ChapterNavigation {

	constructor() {
	}

	static function ID();
	static function LoadChapter(main_instance);
}

/*static*/ function ChapterNavigation::ID()
{
	return "navigation";
}

/*static*/ function ChapterNavigation::LoadChapter(main_instance)
{
	main_instance.AddStep(MessageWindowStep("Navigation chapter - TODO", WAIT));
	//main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_INTRO_2), WAIT));
}
