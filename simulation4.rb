#!/usr/bin/env ruby
# https://vectr.com/tmp/b1vPZfoE0b/a1Q2d7s6e
require './lib/render'
require './lib/physics_verlet'
$stdout.sync = true

class Array
  def each_with_each
    each_with_index do |e, i|
      each_with_index do |e2, i2|
        next if i2 <= i
        next if e == e2
        yield e, e2
      end
    end
  end
  def each_with_each_full
    each do |e|
      each do |e2|
        yield e, e2 unless e == e2
      end
    end
  end
end

class Scene
  include Enumerable
  def initialize(*args)
    @array = Array.new(*args)
  end

  def <<(element)
    @array.push element
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
  include PhysicsVerlet::PhysicsObject
  def initialize(position:, velocity: Vector[0, 0], mass: 1.0)
    sim_params(position: position, velocity: velocity, mass: mass)
  end
end

class HardLink
  include PhysicsVerlet::PhysicsConstrain
  attr_accessor :pair
  def initialize(o1, o2)
    @pair = [o1, o2]
    @distance = (o1.position - o2.position).magnitude
  end

  def step
    o1, o2 = @pair
    r = o2.position - o1.position
    delta = r.magnitude - @distance
    delta *= 0.6
    return unless delta != 0
    if o2.mass > 0
      k = o1.mass / o2.mass
      d1 = delta * k / (1 + k)
      d2 = delta - d1
      o1.position += r.normalize * d2
      o2.position -= r.normalize * d1
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


class Engine
  include PhysicsVerlet::PhysicsForce
  PRIORITY = 0
  def initialize(node:, power: 1.0, dynamics: 1.0)
    @node = node
    @power = power
    @dynamics = dynamics
  end
  def step
    @node.force_sum += Vector[0, -500]
  end
end

class Ship
  def children(&block)
    return enum_for(:children) unless block_given?
    @engines.each(&block)
    @nodes.each(&block)
    @links.each(&block)
  end

  def initialize(position:, velocity: Vector[0, 0], size: 200, mass: 100.0)
    @nodes = [
      Node.new(position: position - Vector[size * 0.5, 0], velocity: velocity, mass: mass * 0.3),
      Node.new(position: position + Vector[-size * 0.3, -size * 0.4], velocity: velocity, mass: mass * 0.35),
      Node.new(position: position + Vector[size * 0.3, -size * 0.4], velocity: velocity, mass: mass * 0.35),
      Node.new(position: position + Vector[size * 0.5, 0], velocity: velocity, mass: mass * 0.3),

      Node.new(position: position + Vector[0, size * 0.05], velocity: velocity, mass: 0),
      Node.new(position: position + Vector[-size * 0.8, size * 0.3], velocity: velocity, mass: mass * 0.01),
      Node.new(position: position + Vector[+size * 0.8, size * 0.3], velocity: velocity, mass: mass * 0.01)
    ]
    @links = [
      [0, 1], [1, 2], [2, 3], [3, 0], [0, 2], [1, 3], [0, 4], [4, 3], [1, 4], [2,4]
    ].map{ |pair| HardLink.new *pair.map{ |i| @nodes[i] } }

    @links << HardLink.new(@nodes[0], @nodes[5])
    @links << SoftLink.new(@nodes[4], @nodes[5])

    @links << HardLink.new(@nodes[3], @nodes[6])
    @links << SoftLink.new(@nodes[4], @nodes[6])

    @engines = []
    @engines << Engine.new(node: @nodes[0])
    @engines << Engine.new(node: @nodes[3])
  end
end

class CollisionDetection
  include PhysicsVerlet::PhysicsForce
  PRIORITY = 100
  def initialize(objects)
    @objects = objects
  end

  def step
    @objects.each do |o|
      if o.position[1] > 400 # && o.velocity[1] > -0.01
        depth = o.position[1] - 400
        o.force_sum += Vector[0, -200 * depth]
        # - bn(n.v)
      end
    end
  end
end

world = Scene.new
world << Ship.new(position: Vector[250, 150])

renderer = Render.new title: 'Ship'
renderer.scene = { objects: world,
                   types: {
                     Node => proc { |r, o|
                           r.circle o.position, o.mass * 0.2
                           glColor3fv [1.0, 0.5, 0.5]
                           r.path [o.position, o.position + o.force * 0.1]
                         },
                     HardLink => { path: ->(a) { a.pair.map(&:position) } },
                     SoftLink => proc { |r, o|
                       glColor3fv [1 - o.displacement * 0.01, 0, 1 + o.displacement * 0.01]
                       r.path o.pair.map(&:position)
                     },
                   }
}

physics = PhysicsVerlet.new
world << CollisionDetection.new(world.select { |o| o.class.ancestors.include? PhysicsVerlet::PhysicsObject })

# Gravity
physics.forces << proc do |obj|
  9.81 * obj.mass * Vector[0, 1]
end

class FPS
  def initialize(title)
    @title = title
    @p_time = Time.new.to_f
    @list = Array.new 100, 0
    @last = Time.now.to_f
  end

  def ping
    @list.push (Time.new.to_f - @last).to_f
    @last = Time.now.to_f
    @list.shift
  end

  def print
    ping
    if Time.new.to_f - @p_time > 2
      avg = @list.inject(&:+) / @list.size
      puts "#{@title} FPS: #{1 / avg}"
      @p_time = Time.new.to_f
    end
  end

end

p_fps = FPS.new :Physics
fps = FPS.new :Render
renderer.run do
  100.times do
    physics.step world
    p_fps.print
  end
  fps.print
end

