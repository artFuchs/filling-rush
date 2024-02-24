

# possible states
# ground
# air
# using_power
# frozen
# dead

def default_player
  {
    w: 8,
    h: 8,
    state: :ground,
    can_double_jump: false,
    powers: {}
  }
end

def set_player_state level

  args.labels << {x: 10, y: 20,
  text: "player.state = #{@level.player.state}",
  r: 255, b:255, g:255}
  args.labels << {x: 10, y: 40,
  text: "player.vel_v = #{@level.player.vel_v}",
  r: 255, b:255, g:255}

  return if level.player.state == :dead

  if level.player.state == :using_power  
    level.player.state = :frozen if args.state.tick_count - level.player.used_power > 60
    return
  end

  blocks = level.blocks
  bellow = level.player.merge(y: level.player.y-1)
  is_on_ground = (collide? bellow, blocks).size > 0 || bellow.y <= $level_box.y

  
  if level.player.state == :frozen && is_on_ground && level.player.vel_v < - 0.7
     p "dead"
     level.player.state = :dead
  end

  return if (level.player.state == :frozen)

  if is_on_ground
    level.player.state = :ground
    level.player.can_double_jump = true
  else
    level.player.state = :air
  end
end


def player_inputs args, player  
  if player.state == :frozen || player.state == :using_power
    return
  end

  if args.nokia.keyboard.key_down.space
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
    frame = (tick_count - player.used_power).idiv(15) % 4
    player.path = "sprites/player_freezing#{frame}.png"
  when :frozen
    player.path = "sprites/player_frozen.png"
  end
end
