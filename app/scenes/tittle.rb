require 'app/game/filler.rb'

class Tittle < Scene
  attr_gtk
  @@borders = {x: 2, y: 2, w: 80, h: 44}

  def initialize
    @blocks = []
    @filler = default_filler @@borders
    @filler.powers = {skip_blocks: true}
    @filler_active = false
    @packs = $gtk.deserialize_state("levels/packs.txt")
    @sel_pack = 0
    @next_scene = Game.new(@packs[@sel_pack].path)
  end

  def tick
    render
    input
    play_intro if @filler_active
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
                                .merge(x: @@borders.x + @@borders.w - 2,
                                       y: 15, text: @packs[@sel_pack].name,
                                       alignment_enum: 2, size_enum: NOKIA_FONT_SM)

      args.nokia.labels << args.nokia
                                .default_label
                                .merge(x: 43,
                                       y: 8, text: "Press Enter",
                                       alignment_enum: 1, size_enum: NOKIA_FONT_SM)
    end

    args.nokia.solids << @blocks

    render_filler args, @filler
  end

  def input
    if inputs.keyboard.key_down.enter
      if !@filler_active
        @next_scene = Game.new(@packs[@sel_pack].path)
        @filler_active = true
        play_sound args, :start
      else
        @over = true
      end
    end

    # if inputs.keyboard.key_down.escape
    #   @next_scene = LevelEditor.new(@packs[@sel_pack].path)
    #   @over = true
    # end

    if inputs.keyboard.key_down.shift or inputs.keyboard.key_down.up
      play_sound args, :jump
      @sel_pack = (@sel_pack+1)%(@packs.size)
    end
  end

  def play_intro
    update_filler @filler, @blocks
    @over = true if @blocks.size > 0
  end


end
