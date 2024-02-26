SOUND_FILES = {
  :jump => 'blip4.wav',
  :portal => 'odd1.wav',
  :goal => 'blip11.wav',
  :evolve => 'blip12.wav',
  :start => 'ring1.wav',
  :fire => 'blip9.wav',
  :intro0005 => 'blip5.wav',
  :intro0047 => 'hit1.wav',
}


def play_sound args, sound
  args.audio["sound"] = {
    input: "sounds/"+SOUND_FILES[sound],
    looping: false
  }
end
