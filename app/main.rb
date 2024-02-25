require 'app/nokia.rb'
require 'app/scenes/scene.rb'
require 'app/scenes/title.rb'
require 'app/scenes/end_scene.rb'
require 'app/scenes/game.rb'
require 'app/scenes/level_editor.rb'

$level_box = {x: 2, y: 2, w: 80, h: 44}
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

  #args.outputs.debug << args.gtk.framerate_diagnostics_primitives
end

def set_scene
  $scene = Title.new
end
