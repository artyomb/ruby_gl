require 'matrix'

class Physics

  module PhysicsObject
    attr_accessor :position, :velocity, :mass
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
    objects.each do |obj|
      others = objects.reject { |o| o == obj }
      next unless obj.class.ancestors.include? PhysicsObject
      obj.position += obj.velocity * delta
      acceleration = @forces.inject(Vector[0,0]) { |sum, force| sum + force.call(obj, others) }
      obj.velocity += acceleration * delta / obj.mass
    end
  end
end
