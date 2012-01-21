
class ChapterIntro {

	constructor() {
	}

	static function ID();
	static function LoadChapter(main_instance);
}

/*static*/ function ChapterIntro::ID()
{
	return "intro";
}

/*static*/ function ChapterIntro::LoadChapter(main_instance)
{
	main_instance.AddStep(CodeStep( function(table) {

				Log.Info("A silly log message from the Intro chapter", Log.LVL_INFO);

				}));

	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_INTRO_1), WAIT));
	main_instance.AddStep(MessageWindowStep(GSText(GSText.STR_INTRO_2), WAIT));
}
