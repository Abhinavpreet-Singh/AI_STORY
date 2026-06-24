class StoryContent {
  const StoryContent({
    required this.title,
    required this.text,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
  final String text;

  static const defaultStory = StoryContent(
    title: "Pip and the Whispering Woods",
    subtitle: "A tale of curiosity, courage, and one shiny blue gear",
    text:
        "Once upon a time, in a valley filled with humming machines and friendly lights, "
        "there lived a clever little robot named Pip. Pip loved to explore, but his favourite "
        "treasure was a shiny blue gear that made his heart whirr with joy.\n\n"
        "One misty morning, while chasing a trail of glittering fireflies, Pip wandered deep "
        "into the Whispering Woods. The trees swayed and seemed to giggle in the wind. "
        "Somewhere between the mossy stones and curling ferns, his precious blue gear slipped "
        "from his pocket and vanished into the soft forest floor.\n\n"
        "Pip did not panic. He listened. He heard the gentle clink of distant metal, the "
        "rustle of leaves, and the faraway hoot of a kind old owl. Every step he took was "
        "brave and curious. Fireflies floated ahead of him like tiny golden lanterns, "
        "lighting up patches of blue moss that sparkled in the dark.\n\n"
        "At last, beside a giggling brook, Pip spotted a flash of brilliant blue. "
        "His gear! It was wedged between two smooth pebbles, safe and shining. "
        "Pip clicked it back into place with a happy whirr, and the whole woods seemed to "
        "cheer. He learned that day that even when something is lost, wonder and courage "
        "can always help you find your way home.",
  );
}
