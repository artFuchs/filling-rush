class LevelEditor < Scene
  attr_gtk

  def initialize(level_num=1) 
    @level_num = level_num
    @block_type = :block
    @selected_blocks = []
    @level = default_level
    @time = 0
    load_level
  end

  def next_scene
    Game.new(@level_num)
  end

  def default_level
    {
      blocks: [],
      player: {},
      goal: {},
      fires: [],
      spikes: [],
      fire: {},
      holes: [],
    }
  end

  def load_level
    parsed_level = $gtk.deserialize_state("levels/level#{@level_num}.txt")
    @level = parsed_level if parsed_level
  end

  def save_level
    $gtk.serialize_state("levels/level#{@level_num}.txt", @level)
  end

  def tick
    defaults
    input
    render
  end

  def defaults
    @level.holes ||= []
    @level.fires ||= []
    @level.spikes ||= []
    @level.blocks ||= []
  end

  def input

    edit_level_input

    if args.nokia.keyboard.control
      # controls to save and load
      save_level if args.nokia.keyboard.key_down.s
      load_level if args.nokia.keyboard.key_down.o
      #controls to change level number
      change_level(1) if args.nokia.keyboard.key_down.plus || args.nokia.keyboard.key_down.equal_sign
      change_level(-1) if args.nokia.keyboard.key_down.hyphen || args.nokia.keyboard.key_down.underscore
    end

    # if enter is pressed, play the level
    if args.inputs.keyboard.key_down.enter
      @over = true
    end
  end

  def change_level(dl)
    @level_num += dl
    @level_num = 1 if @level_num < 1
    @selected_blocks = []
    load_level
  end

  def edit_level_input
    shift = args.nokia.keyboard.shift
    ctrl = args.nokia.keyboard.control

    msg = "" 
    msg += "shift " if shift
    msg += "ctrl" if ctrl 
    args.labels << {x: args.grid.right-10, y: 20, text: msg, alignment_enum: 2, r: 255, g: 255, b: 255}

    @block_type = :block if args.nokia.keyboard.one 
    @block_type = :spike if args.nokia.keyboard.two
    @block_type = :fire if args.nokia.keyboard.three
    @block_type = :big_fire if args.nokia.keyboard.four
    @block_type = :holes if args.nokia.keyboard.five

    block_collection = case @block_type 
    when :block
      @level.blocks
    when :spike
      @level.spikes
    when :fire
      @level.fires
    when :big_fire
      @level.fires
    when :holes
      @level.holes
    end

    args.labels << {x: 10, y: 70, text: "blocks = #{block_collection}"}.merge(r:255, g:255, b:255)

    mouse_pos = {x: args.nokia.mouse.x, y: args.nokia.mouse.y}

    if args.inputs.mouse.button_left
      if not shift
        @selected_blocks = []
      end
      block = find_block block_collection, mouse_pos
      @selected_blocks << block if block and !@selected_blocks.include? block
    end

    if args.inputs.mouse.button_right
      block = find_block block_collection, mouse_pos
      if !block
        case @block_type 
        when :fire
          @level.fires << mouse_pos.merge(w:4, h:4, path: 'sprites/small_fire0.png')
        when :spike
          @level.spikes << mouse_pos.merge(w:4, h:4, path: 'sprites/spike.png')
        when :holes
          @level.holes << mouse_pos.merge(w:1, h:1, r:199, g:240, b:216)
        else
          @level.blocks << mouse_pos.merge(w:1, h:1)
        end
      end
    end

    obj = nil
    obj = :player if args.inputs.keyboard.p
    obj = :goal if args.inputs.keyboard.g
    if obj
      if shift
        @level[obj] = {}
      else
        sprites = {
                    player: { w: 8, h: 8, path: 'sprites/player0.png' },
                    goal: { w: 8, h: 8, path: 'sprites/exit0.png' },
                  }
        @level[obj] = sprites[obj].merge(x: mouse_pos.x, y: mouse_pos.y)
      end
    end

    # clear level
    if args.nokia.keyboard.backspace
      @level = default_level
      @selected_blocks = [] if !ctrl && !shift
    end

    if args.nokia.keyboard.j and @selected_blocks.size > 1 && 
      join_blocks
    end

    dx = args.nokia.keyboard.left_right
    dy = args.nokia.keyboard.up_down
    if (dx != 0 || dy != 0) && @selected_blocks.size > 0 && (passed_time? 5)
      for b in @selected_blocks
        block_collection.delete(b)
      end

      if shift #change block size
        change_blocks_size dx, dy
      else # move blocks
        move_blocks dx, dy
      end

      for b in @selected_blocks
        block_collection << b
      end
    end

    # delete blocks
    if args.nokia.keyboard.space
      for b in @selected_blocks
        block_collection.delete(b)
      end
      @selected_blocks = []
    end
  end

  def change_blocks_size dx, dy
    case @block_type
    when :block
      @selected_blocks = @selected_blocks.map do |b|
        b.merge(w: (b.w+dx).clamp(1,$level_box.w - b.x - 2),
                h: (b.h+dy).clamp(1,$level_box.h - b.y - 1))
      end
    when :holes
      @selected_blocks = @selected_blocks.map do |b|
        b.merge(w: (b.w+dx).clamp(1,$level_box.w - b.x - 2))
      end
    end
  end

  def move_blocks dx, dy
    if @block_type != :holes
      @selected_blocks = @selected_blocks.map do |b|
        b.merge(x: (b.x+dx).clamp($level_box.x + 1, $level_box.x + 1 +  $level_box.w - 2 - b.w),
                y: (b.y+dy).clamp($level_box.y + 1, $level_box.y + 1 + $level_box.h - 2 - b.h))
      end
    else
      @selected_blocks = @selected_blocks.map do |b|
        b.merge(x: (b.x+dx).clamp($level_box.x + 1, $level_box.x + 1 +  $level_box.w - 2 - b.w),
                y: (b.y+dy).clamp($level_box.y, $level_box.y + 1 + $level_box.h - 2 - b.h))
      end
    end
  end

  def join_blocks
    return if @block_type != :block
    min_x = 1000
    min_y = 1000
    max_x = -1
    max_y = -1
    for b in @selected_blocks
      min_x = b.x if b.x < min_x
      min_y = b.y if b.y < min_y
      x = b.x + b.w
      max_x = x if x > max_x
      y = b.y + b.h
      max_y = y if y > max_y
      @level.blocks.delete(b)
    end
    block = {x: min_x, y: min_y, w: max_x - min_x, h: max_y - min_y}
    @level.blocks. << block
    @selected_blocks = [block]
  end


  def find_block blocks, pos
    blocks.find do |b|
      is_inside? pos, b
    end
  end

  def is_inside? pos, obj
    pos.x >= obj.x && pos.x <= obj.x+obj.w &&
    pos.y >= obj.y && pos.y <= obj.y+obj.h
  end

  def mouse_inside_level_area?
    area = $level_box.merge(x: $level_box.x+1,
                            y: $level_box.y+1,
                            w: $level_box.w-2,
                            h: $level_box.h-2)
    args.nokia.mouse.inside_rect? area
  end

  def passed_time? dt
    if (args.state.tick_count - @time) > dt
      @time = args.state.tick_count
      return true
    else
      return false
    end
  end

  def render
    args.nokia.primitives << $level_box.border!
    args.nokia.primitives << @level.holes.map{|h| h.sprite!}
    
    white = {r: 255, g: 255, b: 255}
    args.labels << {x: 10, y: grid.top - 10, text: "LEVEL #{@level_num}"}.merge(white)
    
    args.labels << {x: 10, y: 30, text: "selected_blocks = #{@selected_blocks}"}.merge(white)
    args.labels << {x: 10, y: 50, text: "current_block_type = #{@block_type}"}.merge(white)



    args.nokia.solids << @level.blocks
    args.nokia.sprites << @level.fires
    args.nokia.sprites << @level.spikes
    


    if @level.player
      args.nokia.sprites << @level.player
    end

    if @level.goal
      args.nokia.sprites << @level.goal
    end

    if @level.fire
      args.nokia.sprites << @level.fire
    end



    args.primitives << @selected_blocks.map do |b|
      b.merge(x: b.x*NOKIA_ZOOM + NOKIA_X_OFFSET,
              y: b.y*NOKIA_ZOOM + NOKIA_Y_OFFSET,
              w: b.w*NOKIA_ZOOM,
              h: b.h*NOKIA_ZOOM,
              r:127, b:255, g:127).solid
    end
  end



end
