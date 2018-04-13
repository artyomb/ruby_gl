require 'opengl'
require 'glu'
require 'glut'
include Gl, Glu, Glut

require 'matrix'

class Render
  def point(pos)
    size = 4
    glTranslate pos[0] - size * 0.5, pos[1] - size * 0.5, 0
    glScale size, size, size
    glCallList @quad
  end

  def path(array)
    glBegin GL_LINE_STRIP
    array.each { |v| glVertex2fv v }
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
    @scene = { objects: [], types: {} }
  end

  def render
    glClear GL_COLOR_BUFFER_BIT
    glMatrixMode GL_MODELVIEW
    glLoadIdentity

    glColor3fv [0.1, 1.0, 0.1]
    @scene[:objects].each do |obj|
      types = [scene[:types][obj.class]].flatten
      types.each do |type|
        type.each do |name, func|
          glPushMatrix
          glColor3fv obj.color if obj.respond_to? :color
          send name, func.call(obj)
          glPopMatrix
        end
      end
    end

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
