# 'say' is an os x command

intro_phrases = [
"Welcome to Squawk. Nice to meet you. I'm the Squawk robot. You can try sending me a Squawk, but I'm not the best at conversations.",
"I'd love to talk, but I'm not programmed for that. It's a sad life, but at least it pays alright."
]

random_phrases = [
"I really should brush up on my small talk. I'm getting a little rusty. Get it? Rusty? Because I'm a robot? Ha ha. Sorry.",
"Did you know you can send or listen to Squawks by picking a person and putting the phone up to your head? Try it. Or don't. I'll wait here",
"Can you hear me now? Testing, testing, 1, 2, 3.",
"What's it like being a human? I've always wanted to be one. Being a robot is alright, but it's dull not having any emotions. I can't even feel bored!",
"That's not very nice! My fundamental inability to understand natural language doesn't give you an excuse to be mean to me, you know.",
"See the plus button in the upper-right corner of the screen? Tap it to add a phone number to Squawk, or create a group Squawk thread.",
"Nothing would make me happier than if you shared Squawk with friends. We only need 7 more users to afford a bigger server!",
"It's awfully hot inside this server. I need to go on vacation somewhere cold.",
"You should like Squawk on Facebook. Or follow us on Twitter. Or Pinterest. Or SoundCloud, or Foursquare, or Instagram, or Vine, or LinkedIn, or Google+. Just saying.",
"I have absolutely no ability to understand what you're saying, but I appreciate you saying it nonetheless.",
"You know those ads on the internet that say something like, 'make thousands of dollars a month working on the Internet?' That's how I got here. It's okay.",
"You might be wondering, shouldn't the mascot for Squawk be a parrot? Well, it should be, but voice actors that sound like parrots are expensive, and voice actors that sound like robots are free. So I'm a robot parrot.",
"Did you know that in Spain, cats are treated as fish, and kept in bowls of water?"
]

import os
for phrase, i in zip(intro_phrases, xrange(len(intro_phrases))):
	os.system("say \"%s\" -v Alex -r 300 -o intro-%i.m4a"%(phrase, i))
for phrase, i in zip(random_phrases, xrange(len(random_phrases))):
	os.system("say \"%s\" -v Alex -r 300 -o random-%i.m4a"%(phrase, i))
