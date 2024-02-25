class EndScene < Scene

  def initialize(deaths)
    @deaths = deaths
    @borders = {x: 2, y: 2, w: 80, h: 44}
    @tick_count = 0
  end

  def next_scene
    Title.new
  end

  def tick
    if @tick_count == 0
      play_sound args, :start
    end

    @tick_count += 1
    render
    input
  end

  def input
    @over = true if inputs.keyboard.key_down.enter
    #@deaths += 1 if inputs.keyboard.key_down.right
    #@deaths -= 1 if inputs.keyboard.key_down.left
    @deaths = 0 if @deaths < 0
  end

  def render
    top = @borders.y + @borders.h
    middle_x = @borders.x + @borders.w/2
    right = @borders.x + @borders.w
    args.nokia.borders <<  @borders

    args.nokia.sprites << {
        x: 18, y: 28, w: 50, h: 15, path: "sprites/you_are_on_fire.png"
      }

    args.nokia.labels << args.nokia
                              .default_label  
                              .merge(x: middle_x,
                                      y: top - 24, text: "DEATHS: #{@deaths}",
                                      alignment_enum: 1, size_enum: NOKIA_FONT_SM)

    if (args.state.tick_count/30)%3 > 1
      args.nokia.sprites << {
        x: 18, y: 4, w: 48, h: 8, path: "sprites/press_enter.png"
      }
    end

    
  end
end
