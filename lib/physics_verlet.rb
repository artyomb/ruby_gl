require 'matrix'

class PhysicsVerlet
  # second / metre / kilogram
  # Force Newton (N) = kg⋅m⋅s−2
  # Joule(J) = N⋅m = kg⋅m2⋅s−2
  # Watt = J/s = kg⋅m2⋅s−3
  STEP_TIME = 0.01 # sec
  VECTOR_ZERO = Vector[0, 0].freeze

  module PhysicsForce; end
  module PhysicsConstrain; end

  module PhysicsObject
    attr_accessor :position, :position_prev, :mass, :anchor
    attr_accessor :force_sum, :force
    def sim_params(position:, velocity: VECTOR_ZERO, mass: 1.0, anchor: false)
      @position = position
      @position_prev = position - velocity * STEP_TIME * 0.0
      @mass = mass
      @force_sum = VECTOR_ZERO
      @force = VECTOR_ZERO
      @anchor = anchor
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
      next if obj.anchor
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
    10.times { @physics_constrains.each(&:step) }
  end
end

class Node
  include PhysicsVerlet::PhysicsObject
  def initialize(position:, velocity: Vector[0, 0], mass: 1.0, anchor: false)
    sim_params(position: position, velocity: velocity, mass: mass, anchor: anchor)
  end
end

class HardLink
  include PhysicsVerlet::PhysicsConstrain
  attr_accessor :pair
  INFINITE_MASS = Float::MAX_EXP
  def initialize(o1, o2)
    @pair = [o1, o2]
    @distance = (o1.position - o2.position).magnitude
  end

  def step
    o1, o2 = @pair
    r = o2.position - o1.position
    delta = r.magnitude - @distance
    delta *= 0.8
    return unless delta != 0

    o1_mass = o1.anchor ? INFINITE_MASS : o1.mass
    o2_mass = o2.anchor ? INFINITE_MASS : o2.mass

    if o2.mass > 0
      k = o1_mass / o2_mass
      d1 = delta * k / (1 + k)
      d2 = delta - d1
      o1.position += r.normalize * d2 unless o1.anchor
      o2.position -= r.normalize * d1 unless o2.anchor
    else
      o2.position -= r.normalize * delta
    end
  end
end

class SoftLink
  include PhysicsVerlet::PhysicsForce
  attr_accessor :pair, :k
  def initialize(o1, o2, k = 300)
    @k = k
    @pair = [o1, o2]
    @distance = (o1.position - o2.position).magnitude
  end

  def displacement
    r = @pair.first.position - @pair.last.position
    r.magnitude - @distance
  end

  def step
    o1, o2 = @pair
    r = o1.position - o2.position
    rn = r.normalize
    delta = r.magnitude - @distance
    delta += 0.1 * (o1.velocity - o2.velocity).dot(rn)
    o1.force_sum += -rn * delta * @k
    o2.force_sum += rn * delta * @k
  end
end
