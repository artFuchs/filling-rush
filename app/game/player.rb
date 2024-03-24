class Player
  attr_gtk
  attr_accessor :bbox, :velocity, :state
  
  def initialize
    @bbox = {x: 0, y: 0, w: 8, h: 8}
    @velocity = {v: 0, h: 0}
    @state = :ground
    @can_double_jump = false
    @hurtbox = parse_hash(args.gtk.parse_json_file('sprites/players/hurtboxes.json'))
    @hitbox = parse_hash(args.gtk.parse_json_file('sprites/players/hitboxes.json'))
  end

  def parse_hash(hash)
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
    new_hash[@type]
  end

  def update_state level
    debug()

    below = @bbox.merge(y: @bbox.y-1)

    if @bbox.w == 12
      @bbox.w = 8
      @bbox.h = 8
      @bbox.x += 2
      @bbox.y += 2
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

  def inputs
    return if @state == :using_power

    if args.nokia.keyboard.key_down.space
      play_sound(args, :evolve)
      @used_power = args.state.tick_count
      @state = :using_power
      @bbox.w = 12
      @bbox.h = 12
      @bbox.x -= 2
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

  def set_sprite
    tick_count = args.state.tick_count

    case @state
      when :ground
        @bbox.w = 8
        @bbox.h = 8
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

  def apply_jump
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
    return @bbox.y+@bbox.h+1 < 0
  end

  def debug
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
  attr_gtk
  
  TIME_TO_MELT = 60
  TIME_TO_FREEZE = 60
  GRAVITY_STEP = -0.1
  MAX_VELOCITY = 1

  attr_accessor :time_to_melt, :time_to_freeze

  def initialize
    @type = :ice
    super
  end

  def update_state
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

    super
  end

  def inputs
    return if [:frozen, :melting].include? @state
    super
  end

  def set_sprite
    super

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
      @hurtbox.x = @bbox.w - @hurtbox.x - @hurtbox.w
      @hitbox.x = @bbox.w - @hitbox.x - @hitbox.w
    end
  end
end