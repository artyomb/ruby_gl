require 'matrix'

class Physics

  module PhysicsForce
  end

  module PhysicsObject
    attr_accessor :position, :velocity, :mass
    attr_accessor :force_list
    def sim_params(position:, velocity: Vector[0, 0], mass: 1.0)
      @position = position
      @velocity = velocity
      @mass = mass
    end
  end

  attr_accessor :forces
  def initialize
    @forces = []
  end

  def step(objects, time)
    @last ||= time.to_f
    delta = time - @last
    delta *= 10
    @last = time.to_f

    physics_objects = objects.select { |o| o.class.ancestors.include? PhysicsObject }
    physics_forces = objects.select { |o| o.class.ancestors.include? PhysicsForce }
                            .sort_by { |o| o.class::PRIORITY }

    physics_objects.each do |obj|
      obj.force_list = []
      others = physics_objects.reject { |o| o == obj }
      obj.force_list += @forces.map { |force| force.call(obj, others) }
    end

    physics_forces.each { |o| o.step(delta) if o.respond_to?(:step) }

    # https://www.myphysicslab.com/springs/single-spring-en.html
    # https://habr.com/post/341986/
    physics_objects.each do |obj|
      force = obj.force_list.inject(&:+)
      obj.velocity += force * delta / obj.mass
      obj.position += obj.velocity * delta
    end
  end
end
