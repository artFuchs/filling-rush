FILLER_ACTIONS =
{
  :inside_wall => :advance_in_wall,
  :outside_wall => :advance_tracing,
  :found_wall => :fill_region,
}

def default_filler borders
  {
    x: borders.x, y: borders.y, w: 1, h: 1,
    min_x: borders.x, min_y: borders.y,
    max_x: borders.x+borders.w, max_y: borders.y+borders.h,
    last_x: borders.x, last_y: borders.y,
    blocks: [], current_region: {},
    state: :inside_wall,
    powers: {  }
  }
end

def update_filler filler, blocks
  method = FILLER_ACTIONS[filler.state]
  self.send method, filler, blocks
end

# filler is inside a wall,or on the stage borders so it just advances until it's out
def advance_in_wall filler, blocks
  return if reached_end? filler
  if (filler.x >= filler.max_x)
    filler.x = filler.min_x
    filler.y += 1
  end
  col = collide? filler, blocks
  col2 = collide? filler, filler.blocks
  if (col.size>0)
    if filler.powers.skip_blocks
      set_filler_on_block_right filler, col
    elsif filler.powers.skip_own_blocks && (col2.size>0)
      set_filler_on_block_right filler, col2
    else
      filler.x += 1
    end
  elsif not (on_border? filler)
    filler.current_region = {x: filler.x, y: filler.y, w:1, h:1}
    filler.state = :outside_wall
  else
    filler.x += 1
  end
end

# filler is out, it advance tracing a region until it get
def advance_tracing filler, blocks
  return if reached_end? filler
  col = collide? filler, blocks
  if (on_border? filler) or (col.size>0)
    filler.state = :found_wall
    filler.last_x = filler.x
    filler.last_y = filler.y
    filler.x -= 2
  else
    filler.x += 1
    filler.current_region.w = filler.x - filler.current_region.x
  end
end

# filler was traciong region but found a wall
def fill_region filler, blocks
  return if reached_end? filler
  blocks1 = blocks.map do |b|
    b.merge(y:b.y-1)
  end
  col = collide? filler.current_region, blocks1
  if (col.size > 0) or (on_border? filler)
    filler.state = :inside_wall
    filler.x = filler.last_x
    filler.y = filler.last_y
    blocks << filler.current_region
    filler.blocks << filler.current_region
    filler.current_region = {}
  else
    filler.y += 1
    filler.current_region.h = filler.y - filler.current_region.y
  end
end

def set_filler_on_block_right filler, blocks
  x = filler.x
  for b in blocks
    b_end = b.x + b.w
    x = b_end if b_end > x
  end
  filler.x = x
end


def reached_end? filler
  (filler.x == filler.max_x) and (filler.y == filler.max_y)
end


def on_border? filler
  (filler.x <= filler.min_x) or (filler.x >= filler.max_x-1) or
  (filler.y <= filler.min_y) or (filler.y >= filler.max_y)
end

def render_filler args, filler
  args.nokia.sprites << @filler.merge(x: @filler.x-2, y:@filler.y-1, w: 3, h: 3, path: "sprites/filler.png")
  filler_frame = (args.state.tick_count/4).floor%2
  args.nokia.solids << @filler.current_region if filler_frame>0
end
