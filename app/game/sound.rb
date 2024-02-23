SOUND_FILES = {
  :jump => 'blip4.wav',
  :die => 'odd1.wav',
  :goal => 'blip11.wav',
  :evolve => 'odd3.wav',
  :start => 'ring1.wav'
}


def play_sound args, sound
  args.audio[sound] = {
    input: "sounds/"+SOUND_FILES[sound],
    looping: false
  }
end
