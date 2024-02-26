class Intro < Scene
    attr_gtk

    def initialize
        @time = 0
    end

    def next_scene
        Title.new 
    end

    def tick
        @over = true  if keyboard.key_down.enter
        @time += 1

        key_frames = [0,5,11,17,22,26,30,34,36,39,42,47]

        fps = 8
        c_frame = @time.idiv(fps)
        c_keyframe = key_frames.find_all{|k| k < c_frame}.last
        
        frame_str = c_keyframe.to_s.rjust(4,'0');
        path = "sprites/intro/frame#{frame_str}.png"
        args.nokia.sprites << {x: 0, y: 0, w: 84, h: 48, path: path}

        @over = true if c_frame > 60
    end

    

    


end