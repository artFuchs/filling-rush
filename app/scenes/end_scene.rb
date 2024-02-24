class EndScene < Scene

  def initialize(deaths,time)
    @deaths = deaths
    @time = time
    @borders = {x: 2, y: 2, w: 80, h: 44}
    @tick_count = 0
    @phrases = $gtk.deserialize_state("levels/end_quotes.txt")
  end

  def next_scene
    Tittle.new
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

    # @deaths += 1 if inputs.keyboard.key_down.right
    # @deaths -= 1 if inputs.keyboard.key_down.left
    # @time += 600 if inputs.keyboard.key_down.up
    # @time -= 600 if inputs.keyboard.key_down.down

  end

  def render
    top = @borders.y + @borders.h
    middle_x = @borders.x + @borders.w/2
    right = @borders.x + @borders.w
    args.nokia.borders <<  @borders

    args.nokia.labels << args.nokia
                              .default_label
                              .merge(x: right - 2,
                                     y: top - 4, text: "FINISHED!",
                                     alignment_enum: 2, size_enum: NOKIA_FONT_SM)

    args.nokia.labels << args.nokia
                              .default_label
                              .merge(x: @borders.x + 2,
                                     y: top - 12, text: "Deaths: #{@deaths}",
                                     alignment_enum: 0, size_enum: NOKIA_FONT_SM)

    args.nokia.labels << args.nokia
                             .default_label
                             .merge(x: @borders.x + 5,
                                    y: top - 18, text: get_phrase(@phrases.deaths, @deaths),
                                    alignment_enum: 0, size_enum: NOKIA_FONT_SM)
    minutes = (@time/(3600)).floor
    seconds = (@time/(60)).floor % 60
    minutes = 99 if minutes > 99
    seconds = 99 if minutes > 99
    time_str = "Time: %02d:%02d"%[minutes,seconds]
    args.nokia.labels << args.nokia
                             .default_label
                             .merge(x: @borders.x + 2,
                                    y: top - 24, text: time_str,
                                    alignment_enum: 0, size_enum: NOKIA_FONT_SM)

    args.nokia.labels << args.nokia
                             .default_label
                             .merge(x: @borders.x + 5,
                                    y: top - 30, text: get_phrase(@phrases.time, @time),
                                    alignment_enum: 0, size_enum: NOKIA_FONT_SM)


    if (args.state.tick_count/30)%3 > 1
      args.nokia.labels << args.nokia
                               .default_label
                               .merge(x: middle_x,
                                      y: @borders.y+6, text: "Press Enter",
                                      alignment_enum: 1, size_enum: NOKIA_FONT_SM)
    end

  end

  def get_phrase phrases, var
    key = 50
    for k in phrases.keys
      if k <= var
        key = k
      end
    end
    return phrases[key]
  end
end
