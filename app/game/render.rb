PORTAL_TIME = 30
TRANSITION_TIME = 60


def render

    render_level()
    
    render_player()

    # render particles
    if @level.particles
      args.nokia.solids << @level.particles
    end

    render_reset_indication() if @idle > 60*4
    render_transition()
    render_pause()
  end

  def render_level()
    # render level details
    args.nokia.primitives << $level_box.border!
    args.nokia.primitives << @level.holes.map{|h| h.sprite!}
    args.nokia.sprites << @level.backgrounds if @level.backgrounds
    args.nokia.solids << @level.blocks
    
    args.nokia.sprites << @level.spikes



    # render portal
    if @time - @level.portal.time < PORTAL_TIME
      frame = (@time - @level.portal.time).idiv(5)
      args.nokia.sprites << @level.portal.merge(path: "sprites/portal#{frame}.png")
    end

    # render goal
    goal_frame = (args.state.tick_count/30).floor%2
    if @level.goal
      args.nokia.sprites << @level.goal.merge(path: "sprites/exit#{goal_frame}.png")
    end

    fire_frame = args.state.tick_count.idiv(15)%5
    # render fires
    args.nokia.sprites << @level.fires.map do |f| 
      f.merge(path: "sprites/small_fire#{fire_frame}.png")
    end

    return if !args.state.render_debug_details
    outputs.borders << @level.spikes.map do |s| 
        s.hitbox
    end.concat(@level.fires).map do |h|
        h.merge(
            r: 255, g: 120, b: 100,
            x: NOKIA_X_OFFSET + (h.x)*NOKIA_ZOOM,
            y: NOKIA_Y_OFFSET + (h.y)*NOKIA_ZOOM,
            w: h.w*NOKIA_ZOOM,
            h: h.h*NOKIA_ZOOM
        )
    end


  end

  def render_player
    set_player_sprite
    player = @level.player
    args.nokia.primitives << player.sprite!

    return if !args.state.render_debug_details
    return if !player.hurtbox
    boxes = [player.hurtbox.merge(r: 100, g: 120, b: 255)]
    boxes << player.hitbox.merge(r: 255, g: 120, b: 100) if player.hitbox
    outputs.borders << boxes.map do |h|
        h.merge(
            x: NOKIA_X_OFFSET + (player.x + h.x)*NOKIA_ZOOM,
            y: NOKIA_Y_OFFSET + (player.y + h.y)*NOKIA_ZOOM,
            w: h.w*NOKIA_ZOOM,
            h: h.h*NOKIA_ZOOM
        )
    end
  end


  def render_reset_indication()
    if (args.state.tick_count/30)%3 > 1
      args.nokia.primitives << {
        x: 28, y: 32, w: 31, h: 16, path: "sprites/tutorials/6.png"
    }.sprite!
    end
  end

  def render_transition()
    return if !@in_transition

    args.nokia.sprites << {
      x: 168*(TRANSITION_TIME-@transition_time)/TRANSITION_TIME*2 - 84,
      y: 0, h: 48, w: 84,
      path: :block
      }
  end

  def render_pause()
    return if !@pause      

    args.nokia.primitives << {
      x: 0, y: 0, w: 84, h: 48, path: "sprites/pause.png"
    }.sprite!

    if @level_num < 10
      args.nokia.primitives << {
      x: 65, y: 6, w: 5, h: 7, path: "sprites/numeros/#{@level_num}.png"
      }.sprite!
    else
      args.nokia.primitives << {
      x: 65, y: 6, w: 5, h: 7, path: "sprites/numeros/#{@level_num.to_s[0]}.png"
      }.sprite!
      args.nokia.primitives << {
      x: 69, y: 6, w: 5, h: 7, path: "sprites/numeros/#{(@level_num.to_s[1])}.png"
      }.sprite!
    end
  end