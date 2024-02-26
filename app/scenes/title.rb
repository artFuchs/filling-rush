class Title < Scene
  attr_gtk
  @@borders = {x: 2, y: 2, w: 80, h: 44}

  def initialize
    @next_scene = Game.new()
  end

  def tick
    render
    input
  end

  def render

    @title_x ||= -84

    args.nokia.sprites << {
      x:@title_x + 84, y: 0, w:84, h: 48, path: "sprites/intro/frame0047.png"
    }

    args.nokia.sprites << {
      x:@title_x, y: 0, w:84, h: 48, path: "sprites/title.png"
    }


    if ((args.state.tick_count/30)%3) > 1
      args.nokia.sprites << {
        x: @title_x + 1, y: 1, w: 50, h: 10, path: "sprites/press_enter.png"
      }
    end

    @title_x += 1 if @title_x < 0
  end

  def input
    if inputs.keyboard.key_down.enter
      @next_scene = Game.new()
      play_sound args, :start
      @over = true
    end

    if  inputs.keyboard.key_down.escape
       @next_scene = LevelEditor.new()
       @over = true
    end

    if inputs.keyboard.key_down.shift or inputs.keyboard.key_down.up
      play_sound args, :jump
      @sel_pack = (@sel_pack+1)%(@packs.size)
    end
  end
end
