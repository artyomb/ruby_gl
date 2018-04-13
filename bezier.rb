#!/usr/bin/env ruby
require './lib/render'
require './lib/physics'

class Vector
  def lerp(*); self end
end

class Array
  def lerp(t)
    first.lerp(t) * (1.0 - t) + last.lerp(t) * t
  end

  def to_bi_tree
    size == 2 ? self :
    each_index.map do |index|
      [self[index], self[index + 1]]
    end[0...-1].to_bi_tree
  end
end

def make_lerp_path(tuple, steps)
  Array.new(steps) { |index| tuple.lerp(index.to_f / (steps - 1)) }
end

p [0, 1].to_bi_tree # [0, 1]
p [0, 1, 2].to_bi_tree # [[0, 1], [1, 2]]
p [0, 1, 2, 3].to_bi_tree # [[[0, 1], [1, 2]], [[1, 2], [2, 3]]]

objects = []
# https://stackoverflow.com/questions/6711707/draw-a-quadratic-b%C3%A9zier-curve-through-three-given-points
# connect curves https://www.scratchapixel.com/lessons/advanced-rendering/bezier-curve-rendering-utah-teapot
points = [Vector[10, 10], Vector[210, 50], Vector[150, 250], Vector[400, 10]]
bezier = points.to_bi_tree

objects << Render.grey(points)
objects += points.map { |p| Render.white p }

curve = make_lerp_path(bezier, 30)
objects << Render.green(curve)

# r_proc = Render.proc do |o|
#   color red
#   point o.position
#   path o.path
# end


renderer = Render.new
renderer.scene = { objects: objects, types: {
  Vector => { circle: ->(v) { v } }, Array => { path: ->(a) { a } }
} }

renderer.run
