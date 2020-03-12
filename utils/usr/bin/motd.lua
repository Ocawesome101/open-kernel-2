-- Serve a random MOTD --

local computer = require("computer")

local motds = {
  "Welcome to the dark side-- We have cookies!",
  "Too many secrets",
  "Welcome to Open Shell... what version are we on now?",
  "The shell version is up there. Read it.",
  "Did you know you can put a wireless card in a relay? It's true.",
  "Try /usr/bin/acv, the archive format that's so simple, it's a text file!",
  "Pull requests and contributions are more than welcome.",
  "Find Open Kernel's source code at https://github.com/Ocawesome101/open-kernel-2",
  "Take my weapon! Strike me down! and your journey to the Dark Side will be complete!",
  "Earth is like a tiny grain of sand, only much, much heavier.",
  "If it ain't broke, don't fix it.",
  -- The following lines are taken from The Hitchhiker's Guide to the Galaxy.
  "\"It's at times like this I wish I listened to what my mother said.\"\n\"What did she say?\"\n\"I don't know. I wasn't listening.\"\n\n  -- The Hitchhiker's Guide to the Galaxy",
  "We demand rigidly defined areas of doubt and uncertainty!",
  "He had found a Nutri-Matic machine which had provided him with a plastic cup filled with a liquid that was almost, but not quite, entirely unlike tea.",
  "The spaceships hung in the air in much the same way that bricks don't.",
  "\"It's unpleasantly like being drunk.\"\n\"What's unpleasant about that?\"\n\"Ask a glass of water.\"\n\n  -- The Hitchhiker's Guide to the Galaxy",
  "I demand that my name may or may not be Vroomfondel!"
}

print(("="):rep(32))
print(shell._VERSION .. " on " .. kernel._VERSION .. " - " .. tostring(math.floor(computer.totalMemory()/1024)) .. "k RAM")
print(motds[math.random(1, #motds)])
print(("="):rep(32))
