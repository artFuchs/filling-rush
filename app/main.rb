require 'app/nokia.rb'
require 'app/scenes/scene.rb'
require 'app/scenes/intro.rb'
require 'app/scenes/title.rb'
require 'app/scenes/end_scene.rb'
require 'app/scenes/game.rb'
require 'app/scenes/level_editor.rb'

$level_box = {x: -1, y: 0, w: 86, h: 49, r: 64, g: 82, b: 61}
$scene = nil
def tick args

  if $scene
    $scene.args = args
    $scene.tick
    if $scene.over
      next_scene = $scene.next_scene
      $scene = next_scene
    end
  else
    set_scene
  end


  if args.inputs.keyboard.key_held.minus # if minus key is held
    args.gtk.slowmo!(3) # Slow motion
  end
  if args.inputs.keyboard.key_down.equal
    args.state.render_debug_details ||= false
    args.state.render_debug_details = ! args.state.render_debug_details 
  end
  #args.outputs.debug << args.gtk.framerate_diagnostics_primitives
end

def set_scene
  $scene = Intro.new()
end
