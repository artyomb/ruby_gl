#!/usr/bin/env ruby
# https://vectr.com/tmp/b1vPZfoE0b/a1Q2d7s6e
require './lib/render'
require './lib/physics_verlet'
$stdout.sync = true

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

  # https://vectr.com/tmp/aCds4rYmV/gJq52axTr
  # https://www.youtube.com/watch?v=DFOynlRYT54
  # https://www.reddit.com/r/starcitizen/comments/6n5nza/springy_landing_gear/
  # https://www.gamedev.net/articles/programming/math-and-physics/towards-a-simpler-stiffer-and-more-stable-spring-r3227/
  # http://blog.rectorsquid.com/2018/05/
  # TODO: Blender https://github.com/RMKD/scripting-blender-game-engine/blob/master/tutorial.md
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
world << Ship.new(position: Vector[250, 100])

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
  10.times do
    physics.step world
    p_fps.print
  end
  fps.print
end

