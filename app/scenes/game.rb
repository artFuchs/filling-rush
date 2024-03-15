require 'app/game/physics.rb'
require 'app/game/particles.rb'
require 'app/game/sound.rb'
require 'app/game/player.rb'
require 'app/game/render.rb'

class Game < Scene
  attr_gtk


  def initialize(level_num = 1)
    @level_num = level_num
    @pause = false
    @next_scene = nil
    @time = 0
    @in_transition = false
    @idle = false
    load_level
  end

  def level
    return @level
  end

  def tick
    return if @over
    defaults()
    input()
    update() if !@pause
    render()
    @time += 1 if !@pause
  end

  def defaults
    return if @time > 0

    args.outputs[:block].w = 84
    args.outputs[:block].h = 48 
    args.outputs[:block] << {
      x: 0, y: 0, w: 84, h: 48, r: 64, g: 82, b: 61
    }.solid!

  end

  def input

    @pause = !@pause if args.nokia.keyboard.key_down.enter

    return_title if args.nokia.keyboard.key_down.escape

    if !gtk.production && args.nokia.keyboard.key_down.e
      @next_scene = LevelEditor.new(@level_num)
      @over = true
    end

    return if @in_transition

    reset_level if args.nokia.keyboard.key_down.r or args.nokia.keyboard.key_down.backspace

    return if @pause
    return if (@time - @level.portal.time) < PORTAL_TIME
    player_inputs args, @level.player
  end

  def update
    return if @pause

    if @in_transition
      update_transition()
      return
    end
    
    set_player_state @level

    @level.player = apply_gravity @level.player
    @level.player = move_object @level.player, $level_box, @level.holes, @level.blocks
    
    break_weak_blocks  

    if @level.fires.size == 0
      display_goal
    end

    if player_has_fallen? @level.player
      reset_level
    end

    if @level.player.state == :frozen
      @idle += 1
    else
      @idle = 0
    end
    
    process_collisions()
    @level.particles = move_particles @level.particles
  end

  def process_collisions

    player = @level.player
    hurtbox = player.hurtbox 
    hitbox = player.hitbox


    if hitbox
      player_hitbox = hitbox.merge(
        x: hitbox.x + player.x,
        y: hitbox.y + player.y
      )

      cols = collide? player_hitbox, @level.fires
      if cols.size > 0
        play_sound args, :fire
        unfreeze cols
      end
    end

    return if !hurtbox

    player_hurtbox = hurtbox.merge(
      x: hurtbox.x + player.x,
      y: hurtbox.y + player.y
    )

    reset_level if (collide? player_hurtbox, @level.spikes.map{|s| s.hitbox} + @level.fires).size > 0
    next_level if (collide? player_hurtbox, [@level.goal]).size > 0
  end

  def unfreeze fires
    @level.player.state = :melting
    @level.player.time_to_melt /= 2 if @level.player.time_to_melt != nil
    @level.fires.reject! do |f|
      fires.include? f
    end
  end

  def display_goal
    parsed_level = $gtk.deserialize_state("levels/level#{@level_num}.txt")
    if parsed_level && parsed_level.goal
      @level.goal = parsed_level.goal
    end
  end

  def break_weak_blocks
    return if ![:frozen,:melting].include? @level.player.state

    below = @level.player.merge(y: @level.player.y - 1)
    weak_blocks = @level.blocks.find_all do |b|
      b.h == 1
    end
    cols = collide? below, weak_blocks
    @level.blocks.reject! do |b|
      cols.include? b
    end
  end

  def next_level
    # create explosion effect
    g = @level.goal
    point = { x: g.x + g.w/2,
              y: g.y + g.h/2 }
    @level.particles = create_explosion point
    play_sound args, :portal

    @in_transition = true
    @transition_time = TRANSITION_TIME
  end

  def update_transition
    return if !@in_transition

    @transition_time -= 1

    @in_transition = false if @transition_time <= 0

    return if @transition_time != (TRANSITION_TIME/2) + 10

    if @next_scene && @next_scene.class.name == "Title" || @next_scene.class.name == "EndScene"
      @over = true
    else
      # change level
      @level_num += 1
      load_level
    end

  end

  def reset_level
    p = @level.player
    point = { x: p.x + p.w/2,
              y: p.y + p.h/2 }
    @level.particles = create_explosion point
    play_sound args, :portal
    load_level
    @pause = false
  end

  def load_level
    parsed_level = $gtk.deserialize_state("levels/level#{@level_num}.txt")
    if parsed_level
      particles = [] 
      particles = @level.particles if @level
      @level = parsed_level
      @level.blocks ||= []
      @level.fires ||= []
      @level.spikes ||= []
      @level.spikes = @level.spikes.map {|s| s.merge( hitbox: {x: s.x + 1, y: s.y + 1, w: s.w - 2, h: s.h - 2})}
      @level.holes ||= []
      @level.particles = particles
      @level.player = default_player.merge(@level.player)
      player = @level.player
      p player
      p @level.fires
      @level.portal = {x: player.x - 2, y: player.y - 2, w: 12, h: 12, time: @time}
      if @level.goal
        @level.goal = nil
      end
    else
      end_game
    end
  end

  def end_game
    @next_scene = EndScene.new()
    @over = true
  end

  def return_title
    @next_scene = Title.new
    @transition_time = TRANSITION_TIME
    @in_transition = true
  end



end