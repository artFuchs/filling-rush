class LevelEditor < Scene
  attr_gtk

  def initialize(level_num=1) 
    @level_num = level_num
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
      fire: {},
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
    input
    render
  end


  def input

    edit_level_input

    if args.nokia.keyboard.control
      # controls to save and load
      save_level if args.nokia.keyboard.key_down.s
      load_level if args.nokia.keyboard.key_down.o
      #controls to change level number
      if args.nokia.keyboard.key_down.plus || args.nokia.keyboard.key_down.equal_sign
        @level_num += 1
        @selected_blocks = []
        load_level
      elsif args.nokia.keyboard.key_down.hyphen || args.nokia.keyboard.key_down.underscore
        @level_num -= 1
        @selected_blocks = []
        load_level
      end
    end

    # if enter is pressed, play the level
    if args.inputs.keyboard.key_down.enter
      @over = true
    end
  end

  def edit_level_input
    shift = args.nokia.keyboard.shift_left
    ctrl = args.nokia.keyboard.control

    if mouse_inside_level_area?
      mouse_pos = {x: args.nokia.mouse.x, y: args.nokia.mouse.y}

      if args.inputs.mouse.button_left
        if not shift
          @selected_blocks = []
        end
        block = find_block mouse_pos
        @selected_blocks << block if block and !@selected_blocks.include? block
      end

      if args.inputs.mouse.button_right
        block = find_block mouse_pos
        if !block
          @level.blocks << mouse_pos.merge(w:1, h:1)
        end
      end

      obj = nil
      obj = :player if args.inputs.keyboard.p
      obj = :goal if args.inputs.keyboard.g
      obj = :fire if args.inputs.keyboard.f
      if obj
        if shift
          @level[obj] = {}
        else
          sprites = {
                      player: { w: 8, h: 8, path: 'sprites/player0.png' },
                      goal: { w: 8, h: 8, path: 'sprites/exit0.png' },
                      fire: { w: 4, h: 4, path: 'sprites/filler.png' }
                    }
          @level[obj] = sprites[obj].merge(x: mouse_pos.x, y: mouse_pos.y)
        end
      end
    end

    # clear level
    if args.nokia.keyboard.backspace
      @level = default_level
      @selected_blocks = [] if !ctrl && !shift
    end

    if args.nokia.keyboard.j and @selected_blocks.size > 1
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


    dx = args.nokia.keyboard.left_right
    dy = args.nokia.keyboard.up_down
    if (dx != 0 || dy != 0) && @selected_blocks.size > 0 && (passed_time? 5)

      for b in @selected_blocks
        @level.blocks.delete(b)
      end

      if ctrl #change block size
        @selected_blocks = @selected_blocks.map do |b|
          b.merge(w: (b.w+dx).clamp(1,$level_box.w - 2), h: (b.h+dy).clamp(1,$level_box.h - 2))
        end
      else # move blocks
        @selected_blocks = @selected_blocks.map do |b|
          b.merge(x: (b.x+dx).clamp($level_box.x + 1, $level_box.x + 1 +  $level_box.w - 2 - b.w),
                  y: (b.y+dy).clamp($level_box.y + 1, $level_box.y + 1 + $level_box.h - 2 - b.h))
        end
      end

      for b in @selected_blocks
        @level.blocks << b
      end
    end

    # delete blocks
    if args.nokia.keyboard.space
      for b in @selected_blocks
        @level.blocks.delete(b)
      end
      @selected_blocks = []
    end
  end


  def find_block pos
    @level.blocks.find do |b|
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
    args.nokia.labels << args.nokia
                              .default_label
                              .merge(x: 2,
                                     y: 46, text: "H:",
                                     alignment_enum: 0)

   args.nokia.labels << args.nokia
                             .default_label
                             .merge(x: 42,
                                    y: 46, text: "LEVEL #{@level_num}",
                                    alignment_enum: 1)

    args.nokia.borders << $level_box

    args.nokia.solids << @level.blocks

    if @level.player
      args.nokia.sprites << @level.player
    end

    if @level.goal
      args.nokia.sprites << @level.goal
    end

    if @level.fire
      args.nokia.sprites << @level.fire
    end

    args.labels << {x: 10, y: 20,
                    text: "selected_blocks = #{@selected_blocks}",
                    r: 255, b:255, g:255}

    args.primitives << @selected_blocks.map do |b|
      b.merge(x: b.x*NOKIA_ZOOM + NOKIA_X_OFFSET,
              y: b.y*NOKIA_ZOOM + NOKIA_Y_OFFSET,
              w: b.w*NOKIA_ZOOM,
              h: b.h*NOKIA_ZOOM,
              r:127, b:255, g:127).solid
    end
  end



end
