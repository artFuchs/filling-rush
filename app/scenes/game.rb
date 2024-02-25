require 'app/game/physics.rb'
require 'app/game/particles.rb'
require 'app/game/sound.rb'
require 'app/game/player.rb'

class Game < Scene
  attr_gtk

  def initialize(level_num = 1)
    @level_num = level_num
    @pause = false
    @next_scene = nil
    @time = 0
    @deaths = 0
    load_level
  end

  def level
    return @level
  end

  def tick
    return if @over
    input
    update if !@pause
    render
    @time += 1 if !@pause
  end

  def input

    @pause = !@pause if args.nokia.keyboard.key_down.enter

    return_title if args.nokia.keyboard.key_down.escape

    if !gtk.production && args.nokia.keyboard.key_down.e
      @next_scene = LevelEditor.new(@level_num)
      @over = true
    end

    reset_level if args.nokia.keyboard.key_down.r or args.nokia.keyboard.key_down.backspace


    if !@pause
      player_inputs args, @level.player
    end
  end

  def render
    minutes = (@time/(3600)).floor
    seconds = (@time/(60)).floor % 60
    minutes = 99 if minutes > 99
    time_str = "%02d:%02d"%[minutes,seconds]


    if @pause      
      args.nokia.labels << args.nokia
                                .default_label
                                .merge(x: 42,
                                       y: 24, text: "PAUSED",
                                       alignment_enum: 1)

      args.nokia.labels << args.nokia
                                .default_label
                                .merge(x: 3,
                                      y: 40, text: "D: #{@deaths}",
                                      alignment_enum: 0)
  
      args.nokia.labels << args.nokia
                                .default_label
                                .merge(x: 43,
                                        y: 40 , text: "LEVEL #{@level_num}",
                                        alignment_enum: 1)

      args.nokia.labels << args.nokia
                                .default_label
                                .merge(x: 82,
                                       y: 40, text: time_str,
                                       alignment_enum: 2)
    end

    args.nokia.primitives << $level_box.border!
    args.nokia.primitives << @level.holes.map{|h| h.sprite!}
    args.nokia.solids << @level.blocks
    args.nokia.sprites << @level.spikes

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
  end



  def update
    set_player_state @level

    @level.player = apply_gravity @level.player
    @level.player = move_object @level.player, $level_box, @level.holes, @level.blocks
    
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
    
    reset_level if (collide? @level.player, @level.spikes).size > 0

    if @level.player.state == :frozen
      next_level if (collide? @level.player, [@level.goal]).size > 0
    end

    if @level.particles
      @level.particles = move_particles @level.particles
    end
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
  
  def next_level
    # create explosion effect
    g = @level.goal
    point = { x: g.x + g.w/2,
              y: g.y + g.h/2 }
    @level.particles = create_explosion point
    play_sound args, :goal
    # change level
    @level_num += 1
    load_level
  end

  def reset_level
    p = @level.player
    point = { x: p.x + p.w/2,
              y: p.y + p.h/2 }
    @level.particles = create_explosion point
    @deaths += 1
    play_sound args, :die
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
      if @level.goal
        @level.goal = nil
      end
    else
      end_game
    end
  end

  def end_game
    @next_scene = EndScene.new(@deaths,@time)
    @over = true
  end

  def return_title
    @next_scene = Title.new
    @over = true
  end



end
