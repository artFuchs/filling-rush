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
    else
      if args.nokia.keyboard.key_down.right
        update_characters
      end
    end
  end

  def render
    top = $level_box.y + $level_box.h + 8
    args.nokia.labels << args.nokia
                              .default_label
                              .merge(x: 2,
                                     y: top, text: "D: #{@deaths}",
                                     alignment_enum: 0)

   args.nokia.labels << args.nokia
                             .default_label
                             .merge(x: 42,
                                    y: top, text: "LEVEL #{@level_num}",
                                    alignment_enum: 1)

    minutes = (@time/(3600)).floor
    seconds = (@time/(60)).floor % 60
    minutes = 99 if minutes > 99
    time_str = "%02d:%02d"%[minutes,seconds]
    args.nokia.labels << args.nokia
                             .default_label
                             .merge(x: 83,
                                    y: top, text: time_str,
                                    alignment_enum: 2)

    if @pause
      args.nokia.labels << args.nokia
                                .default_label
                                .merge(x: 42,
                                       y: top-5, text: "PAUSED",
                                       alignment_enum: 1)
    end

    args.nokia.borders << $level_box
    args.nokia.solids << @level.blocks

    goal_frame = (args.state.tick_count/30).floor%2
    args.nokia.sprites << @level.goal.merge(path: "sprites/exit#{goal_frame}.png")

    set_player_sprite
    args.nokia.sprites << @level.player

    args.nokia.sprites << @level.fire

    if @level.particles
      args.nokia.solids << @level.particles
    end
  end



  def update
    set_player_state @level

    @level.player = apply_gravity @level.player
    @level.player = move_object @level.player, $level_box, @level.blocks
    
    if @level.player.state == :frozen
      unfreeze if (collide? @level.player, [@level.fire]).size > 0
    else
      reset_level if (collide? @level.player, [@level.fire]).size > 0
    end
    
    next_level if (collide? @level.player, [@level.goal]).size > 0

    if @level.particles
      @level.particles = move_particles @level.particles
    end
  end

  def unfreeze
    bellow = @level.player.merge(y: @level.player.y-1)
    if (collide? bellow, @level.blocks).size > 0 || bellow.y <= $level_box.y
      @level.player.state = :ground
    else
      @level.player.state = :air
    end
    @level.fire = { x: 0, y: 0, w: 0, h: 0 }
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
  end

  def load_level reset=false
    parsed_level = $gtk.deserialize_state("levels/level#{@level_num}.txt")
    if parsed_level
      if !@level
        @level = parsed_level
        @level.player.merge(default_player)
      else
        @level.blocks = parsed_level.blocks
        @level.goal = parsed_level.goal
      end
    else
      end_game
    end

    if reset
      @level.player = parsed_level.player
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
