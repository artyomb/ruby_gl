#!/usr/bin/env ruby
require 'matrix'

require 'opengl'
require 'glu'
require 'glut'
include Gl, Glu, Glut
#
class Render
  def point(obj)
    pos = obj.position
    size = 4
    glTranslate pos[0] - size * 0.5, pos[1] - size * 0.5, 0
    glScale size, size, size
    glCallList @quad
  end

  def path(obj)
    glBegin GL_LINE_STRIP
      obj.path.each { |v| glVertex2fv v }
    glEnd
  end

  attr_accessor :scene
  def initialize(width: 500, height: 500)
    glClearColor 0.0, 0.0, 0.0, 0.0
    glShadeModel GL_FLAT

    glutInit
    glutInitDisplayMode GLUT_DOUBLE | GLUT_RGB
    glutInitWindowSize width, height
    glutInitWindowPosition 500, 200
    glutCreateWindow 'Hello'

    glutDisplayFunc method :render
    glutReshapeFunc method :reshape
    glutIdleFunc method :idle

    @quad = glGenLists 1
    glNewList @quad, GL_COMPILE
    glBegin GL_QUADS
    glVertex2fv [0, 0]
    glVertex2f 0 + 1, 0
    glVertex2f 0 + 1, 0 + 1
    glVertex2f 0, 0 + 1
    glEnd
    glEndList
  end

  def render
    glClear GL_COLOR_BUFFER_BIT
    glMatrixMode GL_MODELVIEW
    glLoadIdentity

    glColor3fv [0.1, 1.0, 0.1]
    @scene[:objects].each do |obj|
      types = [scene[:types][obj.class]].flatten
      types.each { |type|
        glPushMatrix
        glColor3fv obj.color if obj.respond_to? :color
        send type, obj
        glPopMatrix
      }
    end if @scene

    glutSwapBuffers
  end

  def reshape(w, h)
    glViewport 0, 0, w, h
    glMatrixMode GL_PROJECTION
    glLoadIdentity
    GLU.Ortho2D 0.0, w, h, 0.0
  end

  def idle
    @block.call self if @block
    glutPostRedisplay
  end

  def run(&block)
    @block = block
    glutMainLoop
  end

end

def Vector.random(range = 0..1.0)
  Vector[rand(range), rand(range)]
end

class Array
  def path; self end
end

class Physics
  def initialize
    @forces = []
    @forces << proc { |obj|
      center = Vector[300, 300]
      k = 0.1
      (center - obj.position).normalize * k
    }
  end

  def step(objects, time)
    @last ||= time.to_f
    delta = time - @last
    delta *= 10
    @last = time.to_f
    objects.each do |obj|
      next unless obj.class.ancestors.include? PhysicsObject
      obj.position += obj.velocity * delta
      acceleration = @forces.inject(Vector[0,0]) { |sum, force| sum + force.call(obj) }
      obj.velocity += acceleration * delta
    end
  end
end



module PhysicsObject
  attr_accessor :position, :velocity, :mass
  def sim_params(position:, velocity: Vector[0, 0], mass: 1.0)
    @position = position
    @velocity = velocity
    @mass = mass
  end
end

class TailedObject
  include PhysicsObject
  attr_accessor :path
  def initialize(position:, velocity: Vector[0, 0])
    @path = []
    @path << position.dup << position.dup
    sim_params(position: position, velocity: velocity)
  end

  def step(time)
    @last ||= time
    if time - @last < 3
      @path[@path.size - 1] = position.dup unless @path.empty?
      return
    end
    @last = time

    @path << position.dup
    size = [@path.size, 6].min
    @path.replace @path[-size..size]
  end
end

objects = []
objects += Array.new(10) {
  TailedObject.new position: Vector.random(0..500),
                   velocity: Vector.random(-1.0..1.0)
}

renderer = Render.new
renderer.scene = { objects: objects, types: { TailedObject => [:point, :path] } }

physics = Physics.new
renderer.run do
  time = Time.now.to_f
  objects.each { |obj| obj.step(time) if obj.respond_to? :step }
  physics.step objects, time
end