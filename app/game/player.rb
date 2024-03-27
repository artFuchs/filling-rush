require 'app/game/physics.rb'

class Player
  GRAVITY_STEP = -0.1
  MAX_VELOCITY = 1

  attr_accessor :sprite, :velocity, :state, :hurtbox, :hitbox, :hurtboxes
  attr_accessor :future_sprite, :future_velocity
  
  def initialize args
    @sprite = {x: 10, y: 10, w: 8, h: 8, dx: 0, dy: 0, path: get_sprite_path(:standing)}
    @velocity = {v: 0, h: 0, dv: 0, dh: 0}
    @state = :ground
    @can_double_jump = false
    @hurtboxes = parse_hash(args.gtk.parse_json_file('sprites/players/hurtboxes.json'))[@type]
    @hitboxes = parse_hash(args.gtk.parse_json_file('sprites/players/hitboxes.json'))[@type]
  end

  def parse_hash hash
    new_hash = {}
    hash.each do |key, value|
      new_key = key.to_sym
      if value.is_a?(Hash)
        new_hash[new_key] = parse_hash(value)
      elsif value.is_a?(Array)
        new_hash[new_key] = value.map { |item| parse_hash(item) }
      else
        new_hash[new_key] = value
      end
    end
    return new_hash
  end

  def update_state args, level
    debug args

    below = @sprite.merge(y: @sprite.y-1)

    if @sprite.w == 12
      @sprite.w = 8
      @sprite.h = 8
      @sprite.x += 2
      @sprite.y += 2
    end

    is_on_ground = (collide? below, level.blocks).size > 0 || below.y == $level_box.y
  
    return if (@state == :frozen)

    if is_on_ground
      @state = :ground
      @can_double_jump = true
    else
      if @state != :gliding
        @state = :air
      end
    end
  end

  def inputs args
    return if @state == :using_power

    if args.nokia.keyboard.key_down.space
      play_sound args, :evolve
      @used_power = args.state.tick_count
      @state = :using_power
      @sprite.w = 12
      @sprite.h = 12
      @sprite.x -= 2
    end
    
    @velocity.h = args.nokia.keyboard.left_right*0.5
    @walking = (@velocity.h != 0)
    @flip_horizontally = false if @velocity.h > 0
    @flip_horizontally = true if @velocity.h < 0
    
    if (args.nokia.keyboard.key_down.up || args.nokia.keyboard.key_down.w)
      apply_jump(args)
    end
  
    @velocity[:v] ||= 0
    if @velocity[:v] < 0
      if @state == :air
        if args.nokia.keyboard.up || args.nokia.keyboard.w
          @state = :gliding
        end
      end
    end
  
    if @state == :gliding
      @velocity[:v] = -0.2
      if (!args.nokia.keyboard.up && !args.nokia.keyboard.w)
        @state = :air
        @velocity[:v] = -1
      end
    end
  end

  def set_sprite args
    tick_count = args.state.tick_count

    case @state
      when :ground
        @sprite.w = 8
        @sprite.h = 8
        if @walking
          frame = (tick_count.idiv(10))%4 + 1
          @path = get_sprite_path(:walking, frame)
          @hurtbox = get_hurtbox(:walking, frame)
          @hitbox = get_hitbox(:walking, frame)
        else
          @path = get_sprite_path(:standing)
          @hurtbox = get_hurtbox(:standing)
          @hitbox = get_hitbox(:standing)
        end
      
      when :air
        @jump ||= {initial_frame: 0, time: tick_count}
        frame = @jump.initial_frame
        frame += 1 if (tick_count > @jump.time + 4)
        if @velocity[:v] >= 0
          @path = get_sprite_path(:jumping, frame)
          @hurtbox = get_hurtbox(:jumping, frame)
          @hitbox = get_hitbox(:default)
        else
          @path = get_sprite_path(:falling)
          @hurtbox = get_hurtbox(:falling)
          @hitbox = get_hitbox(:default)
        end
      
      else
        @hurtbox = get_hurtbox(:default)
        @hitbox = get_hitbox(:default)
    end
  end

  def apply_jump args
    case @state
    when :ground
      play_sound(args, :jump)
      @velocity[:v] = 1.5
      @jump = {initial_frame: 0, time: args.state.tick_count}
    when :air
      if @can_double_jump
        play_sound(args, :jump)
        @velocity[:v] = 1.5
        @jump = {initial_frame: 2, time: args.state.tick_count}
        @can_double_jump = false
      end
    end
  end

  def apply_gravity
    @velocity[:v] = 0 if !@velocity[:v]
    @velocity[:v] += GRAVITY_STEP
    @velocity[:v] = -MAX_VELOCITY if @velocity[:v] < -MAX_VELOCITY
  end

  def apply_inertia
    if @velocity[:h].abs < 0.05
      @velocity[:dh] = 0
    else
      @velocity[:dh] = @velocity[:h] * 0.97
    end
  end

  def apply_movement borders, holes
    @sprite[:dx] = @sprite[:x] + @velocity[:h]
    @sprite[:dy] = @sprite[:y] + @velocity[:v]

    below = @sprite.merge(y: @sprite[:y]-1)
    is_falling = (collide? below, holes).size > 0 || below[:y] < $level_box[:y]
    if is_falling
      @sprite[:dx] = @sprite[:x]
      @sprite[:dy] = @sprite[:y]
      return
    end

    min_x = borders[:x]+1
    max_x = borders[:x]+borders[:w]-1
    min_y = borders[:y]+1

    if @sprite[:dx] < min_x
      @sprite[:dx] = min_x
      @velocity[:dh] = 0
    elsif @sprite[:dx]+@sprite[:w] > max_x
      @sprite[:dx] = max_x-@sprite[:w]
      @velocity[:h] = 0
    end

    if @sprite[:dy] < min_y
      @sprite[:dy] = min_y
      @velocity[:dv] = 0
    end
  end

  def apply_collisions colliders
    cols_x = collide?(self, colliders)
    cols_y = collide?(self, colliders)
    for col in cols_y
      @sprite[:dy] = col[:y] if @velocity[:v] < 0
      @velocity[:v] = 0
    end
  end

  def get_sprite_path(action, frame = 0)
    return "sprites/players/#{@type.to_s}/#{action}#{frame}.png"
  end

  def get_hurtbox(action, frame = 0)
    return @hurtboxes[action][frame]
  end

  def get_hitbox(action, frame = 0)
    return @hitboxes[action][frame]
  end

  def has_fallen?
    return @sprite.y+@sprite.h+1 < 0
  end

  def debug args
    if !args.gtk.production
      args.labels << {x: 10, y: 20,
        text: "player.state = #{@state}",
        r: 255, b:255, g:255}
      args.labels << {x: 10, y: 40,
        text: "player.velocity.v = #{@velocity[:v]}",
        r: 255, b:255, g:255}
      args.labels << {x: 10, y: 60,
        text: "player.velocity.h = #{@velocity.h}",
        r: 255, b:255, g:255}
    end
  end
end



class IcePlayer < Player
  TIME_TO_MELT = 60
  TIME_TO_FREEZE = 60

  attr_accessor :time_to_melt, :time_to_freeze

  def initialize args
    @type = :ice
    super args
  end

  def update_state args, level
    if @state == :using_power  
      @time_to_freeze ||= TIME_TO_FREEZE
      @time_to_freeze -= 1
      if (@time_to_freeze <= 0)
        @time_to_freeze = nil 
        @state = :frozen
      end
      return
    end

    return if @state == :frozen

    if @state == :melting
      @time_to_melt ||= TIME_TO_MELT
      @time_to_melt -= 1
      if (@time_to_melt <= 0)
        @time_to_melt = nil 
      end
      return if @time_to_melt != nil;
    end

    super args, level
  end

  def inputs args
    return if [:frozen, :melting].include? @state
    super args
  end

  def set_sprite args
    super args

    case @state
      when :using_power
        return if @time_to_freeze == nil
        frame = (TIME_TO_FREEZE - @time_to_freeze).idiv(15)
        @path = get_sprite_path(:freezing, frame)
        @hurtbox = get_hurtbox(:freezing, frame)
        @hitbox = get_hitbox(:default)
      
      when :frozen
        @path = get_sprite_path(:frozen)
        @hurtbox = get_hurtbox(:frozen)
        @hitbox = get_hitbox(:frozen)
      
      when :melting
        return if @time_to_melt == nil
        frame = (TIME_TO_MELT - @time_to_melt).idiv(15);
        @path = get_sprite_path(:melting, frame)
        @hurtbox = get_hurtbox(:melting, frame)
        @hitbox = get_hitbox(:melting)
    end

    if @flip_horizontally
      @hurtbox.x = @sprite.w - @hurtbox.x - @hurtbox.w
      @hitbox.x = @sprite.w - @hitbox.x - @hitbox.w
    end
  end
end