#!/usr/bin/env ruby
require './lib/render'
require './lib/physics'

class Vector
  def lerp(t);  self end
  def position; self end
end

class Array
  def lerp(t); first.lerp(t) * (1.0 - t) + last.lerp(t) * t  end
  def path; self end
  def to_bi_tree
    return self if size == 2
    result = []
    each_index do |index|
      next if index == 0
      result << [self[index-1], self[index]]
    end
    result.to_bi_tree
  end
end

def make_lerp_path(tuple, steps)
  steps.times.map { |index| tuple.lerp(index.to_f / (steps - 1)) }
end

objects = []
# https://stackoverflow.com/questions/6711707/draw-a-quadratic-b%C3%A9zier-curve-through-three-given-points
# connect curves https://www.scratchapixel.com/lessons/advanced-rendering/bezier-curve-rendering-utah-teapot
points = [Vector[10, 10], Vector[210, 10], Vector[200, 250], Vector[400, 10]]
bezier_curve = points.to_bi_tree

objects += points
objects << make_lerp_path( bezier_curve, 30)

renderer = Render.new
renderer.scene = { objects: objects, types: {
    Vector => :point, Array => :path
} }

renderer.run