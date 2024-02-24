class Title < Scene
  attr_gtk
  @@borders = {x: 2, y: 2, w: 80, h: 44}

  def initialize
    @blocks = []
    @next_scene = Game.new()
  end

  def tick
    render
    input
  end

  def render

    title = ["Filling", "Rush", "3310"]

    args.nokia.borders << @@borders

    (title.size).times do |i|
      args.nokia.labels << args.nokia
                                .default_label
                                .merge(x: @@borders.x + @@borders.w - 2,
                                       y: @@borders.y + @@borders.h - 4 -(i*9),
                                       text: title[i],
                                       alignment_enum: 2, size_enum: NOKIA_FONT_MD)
    end


    if ((args.state.tick_count/30)%3) > 1
      args.nokia.labels << args.nokia
                                .default_label
                                .merge(x: 43,
                                       y: 8, text: "Press Enter",
                                       alignment_enum: 1, size_enum: NOKIA_FONT_SM)
    end

    args.nokia.solids << @blocks
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
