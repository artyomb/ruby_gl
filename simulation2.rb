#!/usr/bin/env ruby
# https://vectr.com/tmp/b1vPZfoE0b/a1Q2d7s6e
require './lib/render'
require './lib/physics'

def Vector.random(range = 0..1.0)
  Vector[rand(range), rand(range)]
end

class TailedObject
  include Physics::PhysicsObject
  attr_accessor :path
  def initialize(position:, velocity: Vector[0, 0])
    @path = []
    @path << position.dup << position.dup
    sim_params(position: position, velocity: velocity)
  end

  def step(time)
    @last ||= time
    if time - @last < 3
      @path[0] = position.dup unless @path.empty?
      return
    end
    @last = time

    @path.unshift position.dup
    @path.slice!(6..-1)
  end
end

objects = []
objects += Array.new(10) { TailedObject.new position: Vector.random(0..500), velocity: Vector.random(-1.0..1.0) }

renderer = Render.new
renderer.scene = { objects: objects,
                   types: { TailedObject => { circle: ->(o) { o.position }, path: ->(o) { o.path } } } }

physics = Physics.new
physics.forces << proc do |obj|
  center = Vector[300, 300]
  k = 0.1
  (center - obj.position).normalize * k
end

renderer.run do
  time = Time.now.to_f
  objects.each { |obj| obj.step(time) if obj.respond_to? :step }
  physics.step objects, time
end