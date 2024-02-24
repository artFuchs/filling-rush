$maximum_vel = 1
$grav_step = - 0.1

def apply_gravity obj
  v = 0
  v = obj.vel_v if obj.vel_v
  v = v + $grav_step
  v = -$maximum_vel if v < (-$maximum_vel)
  obj.merge(vel_v: v)
end

def move_object obj, borders, colliders
  if obj.state == :air || obj.state == :frozen
    apply_inertia obj
  end
  future = move_restricting_to_borders obj, borders
  obj2 = move_checking_collisions obj, future, colliders
  return obj2
end

def apply_inertia obj
  vel_h = 0
  vel_h = obj.vel_h if obj.vel_h
  if obj.last_vel_h != 0 && obj.vel_h == 0
    vel_h = obj.last_vel_h * 0.97
  end
  obj.vel_h = vel_h
end

def move_restricting_to_borders obj, borders
  vel_h = 0
  vel_h = obj.vel_h if obj.vel_h
  vel_v = 0
  vel_v = obj.vel_v if obj.vel_v
  dx = obj.x + vel_h
  dy = obj.y + vel_v

  min_x = borders.x+1
  max_x = borders.x+borders.w-1
  min_y = borders.y+1
  max_y = borders.y+borders.h-1

  if dx < min_x
    dx = min_x
    vel_h = 0
  elsif dx+obj.w > max_x
    dx = max_x-obj.w
    vel_h = 0
  end

  if dy < min_y
    dy = min_y
    vel_v = 0
  elsif dy+obj.h > max_y
    dy = max_y-obj.h
    vel_v = 0
  end

  return obj.merge(x: dx, y: dy, vel_h: vel_h, vel_v: vel_v)
end

def move_checking_collisions obj, future, colliders
  future_x = future.merge(y: obj.y)
  future_y = future.merge(x: obj.x)
  cols_x = collide? future_x, colliders
  cols_y = collide? future_y, colliders
  dy = future.y
  vel_v = future.vel_v
  dx = future.x
  vel_h = future.vel_h
  for col in cols_y
    if col
      # if obj is falling on top of collider, stop
      if vel_v < 0 && obj.y >= col.y+col.h-1
        vel_v = 0
        dy = col.y+col.h
      elsif vel_v > 0 && obj.y <= col.y-obj.h+1
        vel_v = 0
        dy = col.y-obj.h
      end
    end
  end
  for col in cols_x
    if col
      if vel_h < 0 && obj.x >= col.x+col.w-1
        vel_h = 0
        dx = col.x+col.w
      elsif vel_h > 0 && obj.x <= col.x-obj.w+1
        vel_h = 0
        dx = col.x-obj.w
      end
    end
  end
  return future.merge(x: dx, y: dy, vel_h: vel_h, vel_v: vel_v)
end



def collide? obj, colliders
  return if !obj
  colliders.find_all do |c|
    if (c.has_key? :x) && (c.has_key? :y) && (c.has_key? :w) && (c.has_key? :h)
      obj.intersect_rect? c
    end
  end
end
