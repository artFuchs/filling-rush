class EndScene < Scene

  def initialize(deaths)
    @deaths = deaths
    @borders = {x: 2, y: 2, w: 80, h: 44}
    @time = 0
  end

  def next_scene
    Title.new
  end

  def tick
    if @time == 0
      play_sound args, :start
    end
    render
    input
    @time += 1
  end

  def input
    @over = true if inputs.keyboard.key_down.enter
    @deaths = 0 if @deaths < 0
  end

  def render

    @thanks_x ||= 84

    key_frames = [0,4,7,8,9,10,11,14,18,20,23,25,29]

    c_frame = @time.idiv(15)
    c_keyframe = key_frames.find_all{|k| k < c_frame}.last
    
    frame_str = c_keyframe.to_s.rjust(4,'0');
    path = "sprites/ending/frame#{frame_str}.png"

    args.nokia.sprites << {x: @thanks_x - 84, y: 0, w: 84, h: 48, path: path}

    if c_keyframe == 0
      goal_frame = args.state.tick_count.idiv(30)%2
      args.nokia.sprites << {x: 53, y: 33, w: 8, h: 8, path: "sprites/exit#{goal_frame}.png"}
    end

    return if c_frame < 35
    @thanks_x -= 1 if @thanks_x > 0
    args.nokia.sprites << {x: @thanks_x, y: 0, w: 84, h: 48, path: "sprites/ending/thanks.png"}
  end
end
