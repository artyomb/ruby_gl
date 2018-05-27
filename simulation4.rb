#!/usr/bin/env ruby
# https://vectr.com/tmp/b1vPZfoE0b/a1Q2d7s6e
require './lib/render'
require './lib/physics'

class Array
  def each_with_each
    each do |e|
      each do |e2|
        next if e == e2
        yield e, e2
      end
    end
  end
end

class Scene
  include Enumerable
  def initialize(array = [])
    @array = array
  end

  def each(&block)
    recursive @array, block
  end

  def recursive(array, visitor)
    array.each do |el|
      el.respond_to?(:children) ? recursive(el.children, visitor) : visitor[el]
    end
  end
end

class Node
  include Physics::PhysicsObject
  def initialize(position:, velocity: Vector[0, 0], mass: 1.0)
    sim_params(position: position, velocity: velocity, mass: mass)
  end
end

class HardLink
  include Physics::PhysicsForce
  PRIORITY = 1
  attr_accessor :list
  def initialize(array)
    @list = array
    @distances = {}
    @list.each_with_each do |o, o2|
      @distances["#{o.object_id}-#{o2.object_id}"] = (o.position - o2.position).magnitude
    end
  end

  def step
    @list.each_with_each do |o, o2|
      original = @distances["#{o.object_id}-#{o2.object_id}"]
      r = o.position - o2.position
      delta = r.magnitude - original
      o.force_list << -r.normalize * delta * 0.001 rescue nil
      # damping = 0.0001 * (o.velocity - o2.velocity)
      # o.force_list << damping
    end
  end
end

class Engine
  include Physics::PhysicsForce
  PRIORITY = 0
  def initialize(node:, power: 1.0, dynamics: 1.0)
    @node = node
    @power = power
    @dynamics = dynamics
  end
  def step
    @node.force_list << Vector[0, -0.0005]
  end
end

class Ship
  def children(&block)
    return enum_for(:children) unless block_given?
    @engines.each(&block)
    @hard_link.list.each(&block)
    yield @hard_link
  end

  def list; @hard_link.list end
  def link; @hard_link end

  def initialize(position:, velocity: Vector[0, 0], size: 200, mass: 1.0)
    @hard_link = HardLink.new [
      Node.new(position: position - Vector[size * 0.5, 0], velocity: velocity, mass: mass * 0.3),
      Node.new(position: position + Vector[0, -size * 0.4], velocity: velocity, mass: mass * 0.6),
      Node.new(position: position + Vector[size * 0.5, 0], velocity: velocity, mass: mass * 0.1)
    ]
    @engines = []
    @engines << Engine.new(node: @hard_link.list.first)
    @engines << Engine.new(node: @hard_link.list.last)
  end
end

ship = Ship.new(position: Vector[250, 250])
world = Scene.new [ship]

renderer = Render.new title: 'Ship'
renderer.scene = { objects: world,
                   types: { Node => { circle: ->(o) { o.position } },
                            HardLink => { path: ->(a) { a.list.map(&:position) } } }
}

physics = Physics.new

# Gravity
physics.forces << proc do |obj|
  0.001 * obj.mass * Vector[0, 1]
end
# Air
physics.forces << proc do |obj|
  0.0001 * (obj.velocity.magnitude**2) * -obj.velocity.normalize rescue Vector[0,0]
end

renderer.run do
  time = Time.now.to_f * 30
  physics.step world, time
end