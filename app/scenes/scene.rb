class Scene
  attr_gtk
  def initialize
    @over = false
    @next_scene = nil
  end

  def over
    @over
  end

  def next_scene
    @next_scene
  end

  def tick
  end
end
