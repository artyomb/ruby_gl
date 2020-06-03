#!/usr/bin/env ruby
# https://vectr.com/tmp/b1vPZfoE0b/a1Q2d7s6e
require './lib/render'
require './lib/physics_verlet'
require './linkage/linkage'
$stdout.sync = true

class Vector
  def normal
    Vector[self[1], -self[0]].normalize
  end
end

class InputAngle
  include PhysicsVerlet::PhysicsForce
  PRIORITY = 0

  def initialize(root:, node:, force:)
    @root = root
    @node = node
    @force = force * 0.2
    #@node.anchor = true
    @node.mass = 100
  end

  def step
    r = @node.position - @root.position
#    @node.position += r.normal * 0.06 * @force / @force.abs
    @node.force_sum += r.normal * @force
    @root.force_sum -= r.normal * @force
  end
end

bird = Linkage2.new 'linkage/bird2.linkage2'
puts bird.dimensions
nodes = {}
net_links = []
world = []
world += bird.nodes.values.map do |node|
  #mass = node[:anchor] ? 100 : 0.1
  n = Node.new(position: Vector[node[:x], node[:y]], mass: 0.1, anchor: node[:anchor] )
  nodes[node[:id]] = n
end
world += bird.links.values.map do |link|
  list = []
  nodes_ = []
  link[:nodes].each_with_index do |n1, i1|
    nodes_ << nodes[n1[:id]]
    link[:nodes].each_with_index do |n2, i2|
      next unless i2 > i1
      nodes_ << nodes[n2[:id]]
      list << HardLink.new(nodes[n1[:id]], nodes[n2[:id]])
    end
  end
  net_links << NetLink.new(nodes_)
  list
end.flatten

world += bird.inputs.map do |input|
  bird.links.values.select { |l| l[:nodes].any? { |n| n[:id] == input[:id] } }.map do |link|
    link[:nodes].map { |n|
      next if n[:id] == input[:id]
      next if n[:anchor]
      puts "Input Angle: #{input[:id]} -> #{n[:id]} (rpm: #{input[:rpm]})"
      InputAngle.new(root: nodes[input[:id]], node: nodes[n[:id]], force: 10 * input[:rpm])
    }
  end
end.flatten.compact

world += net_links

box = bird.bounding
# Expand the box, not the easiest way though
b_center = (box[0] + box[1]) * 0.5
box.map! { |v| v * 1.5 + b_center * (1 - 1.5) }

renderer = Render.new title: 'Linkage', width: 1000, frame: [box[0][0], box[1][0], box[0][1], box[1][1]]
renderer.scene = { objects: world,
                   types: {
                     Node => proc { |r, o| r.circle o.position, o.mass * 0.04 },
                     HardLink => proc { |r, o| r.path o.pair.map(&:position) }
                   }
}
renderer.overlay do |render|
  glColor3fv [0.6, 0.6, 0.6]
  nodes.values.each do |node|
    render.text node.position[0], node.position[1], node.position.to_a.map{ |v| '%.0f' % v }.join(',')
  end
end

physics = PhysicsVerlet.new

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
      yield if block_given?
    end
  end

end

p_fps = FPS.new :Physics
fps = FPS.new :Render
renderer.run do
  2.times do
    physics.step world
    p_fps.print
  end
  fps.print {
    puts '-------links-----------'
    net_links.each(&:step)
  }
  #sleep 0.01
end


