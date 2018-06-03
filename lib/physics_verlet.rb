require 'matrix'

class PhysicsVerlet
  # second / metre / kilogram
  # Force Newton (N) = kg⋅m⋅s−2
  # Joule(J) = N⋅m = kg⋅m2⋅s−2
  # Watt = J/s = kg⋅m2⋅s−3
  STEP_TIME = 0.005 # sec
  VECTOR_ZERO = Vector[0, 0].freeze

  module PhysicsForce; end
  module PhysicsConstrain; end

  module PhysicsObject
    attr_accessor :position, :position_prev, :mass
    attr_accessor :force_sum, :force
    def sim_params(position:, velocity: VECTOR_ZERO, mass: 1.0)
      @position = position
      @position_prev = position - velocity * STEP_TIME * 0.0
      @mass = mass
      @force_sum = VECTOR_ZERO
      @force = VECTOR_ZERO
    end

    def velocity
      (@position - @position_prev) / STEP_TIME
    end
  end

  attr_accessor :forces
  def initialize
    @forces = []
  end

  def step(objects, delta = STEP_TIME)
    @physics_objects ||= objects.select { |o| o.class.ancestors.include? PhysicsObject }
    @physics_forces ||= objects.select { |o| o.class.ancestors.include? PhysicsForce }
    @physics_constrains ||= objects.select { |o| o.class.ancestors.include? PhysicsConstrain }

    @physics_forces.each(&:step)

    # TODO unreal: http://www.aclockworkberry.com/unreal-engine-substepping/
    # TODO http://physics.weber.edu/schroeder/md/
    # Verlet integration
    # TODO http://lonesock.net/article/verlet.html
    # xi+1 = xi + (xi - xi-1) * (dti / dti-1) + a * dti * dti
    # http://davidlively.com/programming/simple-physics-fun-with-verlet-integration/
    @physics_objects.each do |obj|
      # timeScale = elapsedSeconds / previousFrameTime
      # velocity = (currentTranslation – previousTranslation) * timeScale

      @forces.each { |force| obj.force_sum += force.call(obj, []) }

      prev = obj.position
      df = obj.mass > 0 ? obj.force_sum * delta * delta / obj.mass : VECTOR_ZERO
      obj.position += (obj.position - obj.position_prev + df) * 0.99995
      obj.position_prev = prev

      obj.force = obj.force_sum
      obj.force_sum = VECTOR_ZERO
    end

    # Relaxation / Jacobi / Gauss-Seidel
    1.times { @physics_constrains.each(&:step) }
  end
end
