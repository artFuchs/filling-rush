$maximum_vel = 1
$grav_step = - 0.1

def apply_gravity obj
  v = 0
  v = obj.vel_v if obj.vel_v
  v = v + $grav_step
  v = -$maximum_vel if v < (-$maximum_vel)
  obj.merge(vel_v: v)
end

def move_object obj, borders, holes, colliders
  return obj if obj.state == :using_power
  if obj.state == :frozen || obj.state == :melting
    obj.apply_inertia
  end

  obj.apply_movement borders, holes
  move_checking_collisions(obj, future, colliders)
  # if future.state != :ground
  #   future = fix_clipping(future, colliders)
  # end
  return obj
end

def move_restricting_to_borders obj, borders, holes
  dx = obj.sprite.x + obj.velocity.h
  dy = obj.sprite.y + obj.velocity.v

  below = obj.sprite.merge(y: obj.sprite.y-1)
  is_falling = (inside? below, holes).size > 0 || below.y < $level_box.y
  if is_falling
    obj.sprite.merge(x: dx, y: dy)
    return
  end

  min_x = borders.x+1
  max_x = borders.x+borders.w-1
  min_y = borders.y+1

  if dx < min_x
    dx = min_x
    obj.velocity.h = 0
  elsif dx+obj.sprite.w > max_x
    dx = max_x-obj.sprite.w
    obj.velocity.h = 0
  end

  if dy < min_y
    dy = min_y
    obj.velocity.v = 0
  end

  obj.sprite.merge(x: dx, y: dy)
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

def fix_clipping obj, colliders
  cols = collide? obj, colliders
  if cols.size > 0
    side = get_most_collided_side obj, colliders
    case side
    when :top
      obj = obj.merge(y: cols[0].y-obj.h)
    when :left
      obj = obj.merge(x: cols[0].x+cols[0].w)
    when :right
      obj = obj.merge(x: cols[0].x-obj.w)
    end
  end
  return obj
end

def get_most_collided_side obj, colliders
  cols = collide? obj, colliders
  if cols.size > 0
    count = {top: 0, left: 0, right: 0}
    top = {x: obj.x, y: obj.y+obj.h, w: obj.w, h: 1}
    left = {x: obj.x, y: obj.y, w: 1, h: obj.h}
    right = {x: obj.x+obj.w, y: obj.y, w: 1, h: obj.h}
    for col in cols
      count[:top] += calculate_intersected_area top, col
      count[:left] += calculate_intersected_area left, col
      count[:right] += calculate_intersected_area right, col
    end
    return count.max_by{|side,value| value}[0]
  end
end

def calculate_intersected_area obj, col
  x = [obj.x, col.x].max
  y = [obj.y, col.y].max
  w = [obj.x+obj.w, col.x+col.w].min - x
  h = [obj.y+obj.h, col.y+col.h].min - y
  return w*h
end

def collide? obj, colliders
  return if !obj
  colliders.find_all do |c|
    if c
      if (c.has_key? :x) && (c.has_key? :y) && (c.has_key? :w) && (c.has_key? :h)
        obj.sprite.intersect_rect? c
      end
    end
  end
end

def inside? obj, areas
  return if !obj
  areas.find_all do |c|
    if c && (c.has_key? :x) && (c.has_key? :y) && (c.has_key? :w) && (c.has_key? :h)
      (obj.sprite.intersect_rect? c) && (obj.sprite.x >= c.x) && (obj.sprite.x+obj.sprite.w <= c.x+c.w)
    end
  end
end
