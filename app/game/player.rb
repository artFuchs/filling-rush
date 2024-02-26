

# possible states
# ground
# air
# using_power
# frozen
# melting
# dead

TIME_TO_MELT = 60
TIME_TO_FREEZE = 60

def default_player
  {
    w: 8,
    h: 8,
    state: :ground,
    can_double_jump: false,
    powers: {}
  }
end

def player_has_fallen? player
  return level.player.y+level.player.h+1 < 0
end

def set_player_state level

  args.labels << {x: 10, y: 20,
  text: "player.state = #{@level.player.state}",
  r: 255, b:255, g:255}
  args.labels << {x: 10, y: 40,
  text: "player.vel_v = #{@level.player.vel_v}",
  r: 255, b:255, g:255}
  args.labels << {x: 10, y: 60,
  text: "player.vel_h = #{@level.player.vel_h}",
  r: 255, b:255, g:255}

  if level.player.state == :using_power  
    level.player.time_to_freeze ||= TIME_TO_FREEZE
    level.player.time_to_freeze -= 1
    if (level.player.time_to_freeze <= 0)
      level.player.time_to_freeze = nil 
      level.player.state = :frozen
    end
    return
  end

  return if level.player.state == :frozen

  if level.player.state == :melting
    level.player.time_to_melt ||= TIME_TO_MELT # 1 second
    level.player.time_to_melt -= 1
    if (level.player.time_to_melt <= 0)
      level.player.time_to_melt = nil 
    end
    return if level.player.time_to_melt != nil;
  end

  blocks = level.blocks
  holes = level.holes
  below = level.player.merge(y: level.player.y-1)
  feet = below.merge(x: below.x+below.w/2-1, w: 2)

  if level.player.w == 12
    level.player.w = 8
    level.player.h = 8
    level.player.x += 2
    level.player.y += 2
  end

  is_on_ground = (collide? below, blocks).size > 0 || below.y == $level_box.y
  
  return if (level.player.state == :frozen)

  if is_on_ground
    level.player.state = :ground
    level.player.can_double_jump = true
  else
    level.player.state = :air
  end
end


def player_inputs args, player  
  if player.state == :frozen || player.state == :melting || player.state == :using_power
    return
  end

  if args.nokia.keyboard.key_down.space
    play_sound args, :evolve
    player.state = :using_power
    player.used_power = args.state.tick_count
    player.x -= 2
    player.w = 12
    player.h = 12
  end

  player.vel_h = args.nokia.keyboard.left_right*0.5
  player.walking = (player.vel_h != 0)
  player.flip_horizontally = false if player.vel_h > 0
  player.flip_horizontally = true if player.vel_h < 0
  if (args.nokia.keyboard.key_down.up || args.nokia.keyboard.key_down.w)
    apply_jump args, player
  end
end


def apply_jump args, player
  case player.state
  when :ground
    player.vel_v = 1.5
    play_sound args, :jump
    player.jump = {initial_frame: 0, time: args.state.tick_count}
  when :air
    if player.can_double_jump
      player.vel_v = 1.5
      player.can_double_jump = false
      play_sound args, :jump
      player.jump = {initial_frame: 2, time: args.state.tick_count}
    end
  end
end




def set_player_sprite
  player = @level.player
  tick_count = args.state.tick_count
  case player.state
  when :ground
    player.w = 8
    player.h = 8
    if player.walking
      frame = (tick_count.idiv(10))%4 + 1
      player.path = "sprites/player#{frame}.png"
    else
      player.path = "sprites/player0.png"
    end
  when :air
    player.jump ||= {initial_frame: 0, time: tick_count}
    frame = player.jump.initial_frame
    frame += 1 if (tick_count > player.jump.time + 4) 
    if player.vel_v >= 0
      player.path = "sprites/player_jumping#{frame}.png"
    else
      player.path = "sprites/player_falling.png"
    end
  when :using_power
    return if player.time_to_freeze == nil
    frame = (TIME_TO_FREEZE - player.time_to_freeze).idiv(15)
    player.path = "sprites/player_freezing#{frame}.png"
  when :frozen
    player.path = "sprites/player_frozen.png"
  when :melting
    return if player.time_to_melt == nil
    frame = (TIME_TO_MELT - player.time_to_melt).idiv(15);
    player.path = "sprites/player_melting#{frame}.png"
  end
end