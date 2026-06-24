class StoryContent {
  const StoryContent({
    required this.id,
    required this.title,
    required this.text,
    required this.subtitle,
    required this.emoji,
  });

  final String id;
  final String title;
  final String subtitle;
  final String text;
  final String emoji;
}

class StoryCatalog {
  StoryCatalog._();

  static const stories = <StoryContent>[
    StoryContent(
      id: 'pip_woods',
      emoji: '🤖',
      title: 'Pip and the Whispering Woods',
      subtitle: 'A tale of curiosity, courage, and one shiny blue gear',
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
    ),
    StoryContent(
      id: 'luna_cloud',
      emoji: '🌙',
      title: "Luna's Cloud Castle",
      subtitle: 'A sleepy adventure above the stars',
      text:
          "High above the sleepy town of Maple Hollow, where chimney smoke curled like lazy "
          "dragons, a gentle moon-bot named Luna built a castle from the softest clouds she "
          "could find. Each tower was spun from silver mist, and every window glowed with the "
          "warm light of friendly dreams.\n\n"
          "One evening, a chilly wind whisked through the sky and scattered Luna's favourite "
          "star blanket across the heavens. Without it, the cloud castle felt drafty, and the "
          "dreams below grew restless. Luna wrapped her shimmering scarf around her shoulders "
          "and set off on her sky-sled, gliding past comets that winked like old friends.\n\n"
          "She asked the Great Owl constellation for directions. She followed a trail of "
          "glimmering stardust that tickled her nose and made her giggle. Deeper into the night "
          "she sailed, braver with every breeze, until she found her blanket snagged on the "
          "horn of a friendly crescent moon.\n\n"
          "Luna tugged it free with a grateful hum. She tucked it over her castle, and at once "
          "the whole sky sighed with comfort. Below, children snuggled deeper into their beds, "
          "smiling without knowing why. Luna learned that caring for others can light up the "
          "darkest night.",
    ),
    StoryContent(
      id: 'finn_tide',
      emoji: '🐠',
      title: "Finn and the Singing Tide",
      subtitle: 'A splashy quest beneath the waves',
      text:
          "In a coral cove painted pink and gold, a cheerful robo-fish named Finn loved to "
          "collect shells that hummed little tunes. His favourite shell sang a melody so sweet "
          "that even the grumpiest crabs would tap their claws in time.\n\n"
          "One morning the singing stopped. The shell lay silent on the sand, and the tide "
          "pooled still and grey. Finn's fins fluttered with worry, but his bright eyes "
          "sparkled with determination. He asked the wise old turtle where songs go when they "
          "hide. She whispered, \"Follow the tide that laughs.\"\n\n"
          "Finn dove through forests of kelp that swayed like green ribbons. He raced a school "
          "of silver fish that zigzagged like lightning. He found a sunken music box tangled in "
          "seaweed, its lid stuck shut with salty grit. Finn polished it with his sleeve and "
          "gave it a gentle knock.\n\n"
          "The box popped open, and the melody burst out, rushing back into his shell like a "
          "happy tide. The cove filled with music again, and every creature danced in the "
          "swirling water. Finn learned that patience and kindness can wake up any song.",
    ),
  ];

  static StoryContent? byId(String id) {
    for (final story in stories) {
      if (story.id == id) return story;
    }
    return null;
  }
}
