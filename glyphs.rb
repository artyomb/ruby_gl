#!/usr/bin/env ruby
require 'matrix'
require 'opengl'
require 'glu'
require 'glut'
require 'rmagick'
include Gl, Glu, Glut

class Render

  def save_screenshot(name)
    @count ||= 0
    title = @title
    img = Magick::Image.capture(true) { self.filename = title } # self.filename is actually window title
    img.write name % { count: @count }
    @count += 1
  end

  def point(pos, size=10)
    glPushMatrix
    #glTranslate pos[0] - size * 0.5, pos[1] - size * 0.5, 0
    glTranslate pos[0], pos[1], 0
    glScale size, size, size
    glCallList @quad
    glPopMatrix
  end

  def initialize(width: 500, height: 500, title: 'Glyphs')
    @title = title
    glClearColor 0.0, 0.0, 0.0, 0.0
    glShadeModel GL_FLAT

    glutInit
    glutInitDisplayMode GLUT_DOUBLE | GLUT_RGB
    glutInitWindowSize width, height
    glutInitWindowPosition 500, 200
    glutCreateWindow title

    glutDisplayFunc method :render
    glutReshapeFunc method :reshape
    glutIdleFunc method :idle
    glutKeyboardFunc method :keyboard

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

  def keyboard(key, x, y)
    case key.bytes[0]
    when 27; exit(0) # Escape key
    else @key_block.call key, self if @key_block
    end
    glutPostRedisplay
  end

  def render
    glClear GL_COLOR_BUFFER_BIT
    glMatrixMode GL_MODELVIEW
    glLoadIdentity
    glColor3fv [0.1, 1.0, 0.1]
    @render_block.call self if @render_block
    glutSwapBuffers
  end

  def reshape(w, h)
    glViewport 0, 0, w, h
    glMatrixMode GL_PROJECTION
    glLoadIdentity
    GLU.Ortho2D 0.0, w, h, 0.0
  end

  def idle
    #glutPostRedisplay
  end
  def on_render(&block); @render_block = block end
  def on_key(&block); @key_block = block end

  def run
    glutMainLoop
  end
end


class Glyph
  attr_accessor :points
  def initialize(dimension = 4 )
    @dimension = dimension
    @points = []
    each do |x,y|
      @points << {pos: Vector[x, y], on: [true, false].sample}
    end
  end

  def point(x,y); @points[x + y*@dimension][:on] end

  def each
    (@dimension**2).times { |i| yield i % @dimension, i / @dimension}
  end

  def good?
    no_quads? && no_chess?
  end

  def symmetrical_x?; end

  def no_quads?
    each do |x,y|
      next if x == @dimension-1 || y == @dimension-1
      quad  = [point(x,y), point(x+1,y),point(x,y+1), point(x+1,y+1)]
      return false unless quad.include? false
    end
    true
  end

  def no_chess?
    each do |x,y|
      next if x == @dimension-1 || y == @dimension-1
      quad  = [point(x,y), point(x+1,y),point(x,y+1), point(x+1,y+1)]
      return false if quad == [false, true, true, false]
      return false if quad == [true, false, false, true]
    end
    true
  end

end

dimension = 6
renderer = Render.new width: dimension*100, height: dimension*100

gl = Glyph.new dimension
renderer.on_render do |r|
  gl.points.each { |point| r.point point[:pos]*100, size=100 if point[:on]}
end
renderer.on_key do |k, r|
  :repeat until (gl = Glyph.new dimension).good?
  r.save_screenshot 'glyph_%{count}.jpg' if k == 's'
end

renderer.run