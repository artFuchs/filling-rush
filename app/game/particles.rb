EXPLOSION_DIRECTIONS = [
  {dx: 1,     dy: 0    },
  {dx: 0.75,  dy: -0.75},
  {dx: 0,     dy: -1   },
  {dx: -0.75, dy: -0.75},
  {dx: -1,    dy: 0    },
  {dx: -0.75, dy: 0.75 },
  {dx: 0,     dy: 1    },
  {dx: 0.75,  dy: 0.75 }
]

def create_explosion point
  EXPLOSION_DIRECTIONS.map do |dir|
    dir.merge(x: point.x, y: point.y, w: 1, h: 1, ttl: 30)
  end
end

def move_particles particles
  return if !particles
  particles.map do |p|
    move_particle p
  end.reject do |p|
    p.ttl < 1
  end
end

def move_particle p
  p.x = p.x+p.dx
  p.y = p.y+p.dy
  p.ttl = p.ttl-1
  return p
end

def rand_range range
  range_array = range.to_a
  index = rand (range_array.size)
  return range_array[index]
end
