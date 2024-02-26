require 'app/game/physics.rb'
require 'app/game/particles.rb'
require 'app/game/sound.rb'
require 'app/game/player.rb'

class Game < Scene
  attr_gtk

  PORTAL_TIME = 30

  def initialize(level_num = 1)
    @level_num = level_num
    @pause = false
    @next_scene = nil
    @time = 0
    @deaths = 0
    @in_transition = false
    @idle = false
    load_level
  end

  def level
    return @level
  end

  def tick
    return if @over
    defaults
    if !@in_transition
      input
      update if !@pause
    else 
      update_transition
    end
    if @level.particles
      @level.particles = move_particles @level.particles
    end

    render
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

    reset_level if args.nokia.keyboard.key_down.r or args.nokia.keyboard.key_down.backspace

    return if @pause
    return if (@time - @level.portal.time) < PORTAL_TIME
    player_inputs args, @level.player
  end

  def render
    minutes = (@time/(3600)).floor
    seconds = (@time/(60)).floor % 60
    minutes = 99 if minutes > 99
    time_str = "%02d:%02d"%[minutes,seconds]

    args.nokia.primitives << $level_box.border!
    args.nokia.primitives << @level.holes.map{|h| h.sprite!}
    args.nokia.sprites << @level.backgrounds if @level.backgrounds
    args.nokia.solids << @level.blocks
    args.nokia.sprites << @level.spikes


    if @time - @level.portal.time < PORTAL_TIME
      frame = (@time - @level.portal.time).idiv(5)
      args.nokia.sprites << @level.portal.merge(path: "sprites/portal#{frame}.png")
    end


    goal_frame = (args.state.tick_count/30).floor%2
    if @level.goal
      args.nokia.sprites << @level.goal.merge(path: "sprites/exit#{goal_frame}.png")
    end

    set_player_sprite
    args.nokia.primitives << @level.player.sprite!

    fire_frame = args.state.tick_count.idiv(15)%5
    args.nokia.sprites << @level.fire.merge(path: "sprites/fire#{fire_frame}.png")

    args.nokia.sprites << @level.fires.map do |f| 
      f.merge(path: "sprites/small_fire#{fire_frame}.png")
    end

    if @level.particles
      args.nokia.solids << @level.particles
    end

    if @in_transition
      args.nokia.sprites << {
        x: 168*(TRANSITION_TIME-@transition_time)/TRANSITION_TIME*2 - 84,
        y: 0, h: 48, w: 84,
        path: :block
        }
    end

    if @idle > 60*4
      if (args.state.tick_count/30)%3 > 1
        args.nokia.primitives << {
          x: 28, y: 32, w: 31, h: 16, path: "sprites/tutorials/6.png"
      }.sprite!
      end
    end

    if @pause      
      args.nokia.primitives << {
        x: 0, y: 0, w: 84, h: 48, path: "sprites/pause.png"
      }.sprite!

      args.nokia.primitives << {
      x: 65, y: 6, w: 5, h: 7, path: "sprites/numeros/#{@level_num}.png"
      }.sprite!

    end
  end



  def update
    set_player_state @level

    @level.player = apply_gravity @level.player
    @level.player = move_object @level.player, $level_box, @level.holes, @level.blocks
    
    break_weak_blocks

    cols = collide? @level.player, @level.fires
    if cols.size > 0
      if @level.player.state == :frozen || @level.player.state == :melting
        unfreeze cols
      else
        reset_level
      end
    end

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
    
    reset_level if (collide? @level.player, @level.spikes).size > 0

    next_level if (collide? @level.player, [@level.goal]).size > 0
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


  TRANSITION_TIME = 60
  def update_transition
    return if !@in_transition

    @transition_time -= 1

    @in_transition = false if @transition_time <= 0

    if @transition_time == (TRANSITION_TIME/2)
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
    @deaths += 1
    play_sound args, :portal
    load_level true
    @pause = false
  end

  def load_level reset=false
    parsed_level = $gtk.deserialize_state("levels/level#{@level_num}.txt")
    if parsed_level
      particles = [] 
      particles = @level.particles if @level
      @level = parsed_level
      @level.blocks ||= []
      @level.fires ||= []
      @level.spikes ||= []
      @level.holes ||= []
      @level.particles = particles
      player = @level.player
      @level.portal = {x: player.x - 2, y: player.y - 2, w: 12, h: 12, time: @time}
      if @level.goal
        @level.goal = nil
      end
    else
      end_game
    end
  end

  def end_game
    @next_scene = EndScene.new(@deaths)
    @over = true
  end

  def return_title
    @next_scene = Title.new
    @over = true
  end



end