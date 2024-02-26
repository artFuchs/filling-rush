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

        time_to_start = 180

        key_frames = [0,5,11,17,22,26,30,34,36,39,42,47]

        c_frame = 0

        if @time > time_to_start
            c_frame = (@time - time_to_start).idiv(8)
        end

        c_keyframe = key_frames.find_all{|k| k < c_frame}.last
        
        frame_str = c_keyframe.to_s.rjust(4,'0');
        path = "sprites/intro/frame#{frame_str}.png"
        args.nokia.sprites << {x: 0, y: 0, w: 84, h: 48, path: path}


        if @time < 60
            args.nokia.sprites << {x: 0, y: 0, w: 84, h: 48, path: "sprites/intro/credits_dr.png"} 
        elsif @time < time_to_start && @time > 70
            args.nokia.sprites << {x: 0, y: 0, w: 84, h: 48, path: "sprites/intro/credits_creators.png"} 
        end
            


        if c_frame == 5
            play_sound args, :intro0005
        end

        if c_frame == 22
            play_sound args, :evolve
        end

        if c_frame == 47
            play_sound args, :intro0047
        end

        @over = true if c_frame > 60
    end

    

    


end