

# possible states
# ground
# air

def default_player
  {
    state: :ground,
    can_double_jump: false,
    powers: {}
  }
end

def set_player_state level
  blocks = level.blocks
  bellow = level.player.merge(y: level.player.y-1)

  if args.nokia.keyboard.key_down.space
    level.player.state = :frozen
  end

  if level.player.state == :frozen
    return
  end

  if (collide? bellow, blocks).size > 0 || bellow.y <= $level_box.y
    level.player.state = :ground
    level.player.can_double_jump = true
  else
    level.player.state = :air
  end
end





def player_inputs args, player
  if player.state == :frozen
    return
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
  when :air
    if player.can_double_jump
      player.vel_v = 1.5
      player.can_double_jump = false
      play_sound args, :jump
    end
  end
end




def set_player_sprite
  case @level.player.state
  when :ground
    if @level.player.walking
      frame = (args.state.tick_count/10).floor%2
      @level.player.path = "sprites/player#{frame}.png"
    else
      @level.player.path = "sprites/player0.png"
    end
  when :air
    if @level.player.vel_v >= 0
      @level.player.path = "sprites/player_jumping.png"
    else
      @level.player.path = "sprites/player_falling.png"
    end
  end
end
