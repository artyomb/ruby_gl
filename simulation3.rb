#!/usr/bin/env ruby
# https://vectr.com/tmp/b1vPZfoE0b/a1Q2d7s6e
require './lib/render'
require './lib/physics'

def Vector.random(range = 0..1.0)
  Vector[rand(range), rand(range)]
end

class MagnetObject
  include Physics::PhysicsObject
  def initialize(position:, velocity: Vector[0, 0], mass: 1.0)
    sim_params(position: position, velocity: velocity, mass: mass)
  end
end

objects = []
objects << MagnetObject.new( position: Vector[150, 150], mass: 1.0, velocity: Vector.random(-1.0..1.0)*0.0 )
objects << MagnetObject.new( position: Vector[300, 250], mass: 50.0, velocity: Vector[0, 0.5]*0.0 )
objects << MagnetObject.new( position: Vector[200, 250], mass: 50.0, velocity: Vector[0, -0.5]*0.0 )

objects = objects.map { |o| Render.green o }
links = objects + [objects.first]
links = Render.grey links # links.render.grey.size(2)

renderer = Render.new title: 'N-body problem'
renderer.scene = { objects: [links] + objects,
                   types: { MagnetObject => { circle: ->(o) { o.position } },
                            Array => { path: ->(a) { a.map(&:position) } } }
}

physics = Physics.new

# Gravity
physics.forces << proc do |obj, others|
  k = 0.2
  others.map { |o|
    r = o.position - obj.position
    k * o.mass * obj.mass * r.normalize / r.magnitude.abs2
  }.inject(&:+)
end

# Proximity limit
physics.forces << proc do |obj, others|
  k2 = 0.2
  others.map { |o|
    r = o.position - obj.position
    r.magnitude < 100 ? - k2 * r.normalize / r.magnitude : Vector[0, 0]
  }.inject(&:+)
end

renderer.run do
  time = Time.now.to_f*10
  physics.step objects, time
end