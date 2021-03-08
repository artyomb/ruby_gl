require 'opengl'
require 'glu'
require 'glut'
include Gl, Glu, Glut

require 'matrix'
require 'rmagick'

class Object
  def attr(sym, value)
    define_singleton_method sym, ->() { value }
    self
  end
end

class Render
  def self.green(obj); obj.attr(:color, [0, 1, 0]) end
  def self.grey(obj); obj.attr(:color, [0.3, 0.3, 0.3]) end
  def self.white(obj); obj.attr(:color, [1, 1, 1]) end

  def save_screenshot(name, window_title = @title)
    @scount ||= 0
    img = Magick::Image.capture(true) { self.filename = window_title } # self.filename is actually window title
    img.write name % { count: @scount }
    @scount += 1

    # width, height = glutGet(GLUT_WINDOW_WIDTH), glutGet(GLUT_WINDOW_HEIGHT)
    # pixels = glReadPixels  0, 0, width, height, GL_RGB, GL_UNSIGNED_BYTE
    # img = Magick::Image.new width, height # img = Magick::Image.constitute width, height, 'RGB', pixels.unpack('C*')
    # img.import_pixels 0, 0, width, height, 'RGB', pixels
    # img.display
  end

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

  def circle(pos, size = 7.0, steps = 10)
    glPushMatrix
    glTranslate pos[0], pos[1], 0
    glBegin GL_POLYGON
    #glBegin GL_LINE_LOOP
    i = 0
    while i < 2 * Math::PI
      i += Math::PI / steps
      glVertex3f Math.cos(i) * size, Math.sin(i) * size, 0.0
    end
    glEnd
    glPopMatrix
  end

  attr_accessor :scene
  def initialize(width: 500, height: 500, title: 'Hello', frame: [0, width, height, 0])
    @title = title
    @frame = frame
    @width = width
    @height = height
    aspect1 = @width / @height
    aspect2 = (@frame[1] - @frame[0]) / (@frame[3] - @frame[2])
    @aspect = aspect2 / aspect1

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
    glutMouseFunc method :mouse
    glutMotionFunc method :motion
    glutPassiveMotionFunc method :passive_motion

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
    @pause = false
  end

  def motion(x, y)
    p [x, y]
  end

  def passive_motion(x, y)
    p [x, y]
    glutWarpPointer 100, 100 unless x == 100 && y == 100 || @pause
  end

  def mouse(button, state, x, y)
    glutSetCursor(GLUT_CURSOR_NONE)
    p [button, state, x, y]
    modifiers = glutGetModifiers
    p modifiers
  end

  def keyboard(key, x, y)
    puts "key:#{key.bytes[0]} x:#{x}, y:#{y}"
    case key.bytes[0]
    when 27; exit(0) # Escape key
    when 32
      @pause = @pause ? false : true
    end
  end

  def overlay(&block)
    @overlay_block = block
  end

  def render_overlay
    glMatrixMode GL_PROJECTION
    @overlay_block.call(self) if @overlay_block
#    glPushMatrix
#    glLoadIdentity
#    glOrtho 0, @w, @h, 0, -1, 1
#   text 0,0,"Tile: #{@title}"
#    glPopMatrix
  end

  def text(x, y, text)
    glRasterPos2d x, y
    text.each_byte { |x| glutBitmapCharacter(GLUT_BITMAP_9_BY_15, x) }
  end

  def render
    glClear GL_COLOR_BUFFER_BIT
    glMatrixMode GL_MODELVIEW

    glColor3fv [0.1, 1.0, 0.1]
    @scene[:objects].each do |obj|
      types = [scene[:types][obj.class]].flatten
      types.compact.each do |type|
        glPushMatrix
        obj.respond_to?(:color) ? glColor3fv(obj.color) : glColor3fv([0.1, 1.0, 0.1])
        if type.is_a? Proc
          type.call self, obj
        else
          type.each do |name, func|
            send name, func.call(obj)
          end
        end
        glPopMatrix
      end
    end

    render_overlay
    glutSwapBuffers
  end

  def reshape(w, h)
    @w, @h = w, h
    w_delta =  w.to_f /  @width
    h_delta =  h.to_f /  @height

    h_delta *= @aspect.abs

    scale = [w_delta, h_delta].min

    w_delta /= scale
    h_delta /= scale

    glViewport 0, 0, w, h
    glMatrixMode GL_PROJECTION
    glLoadIdentity
    GLU.Ortho2D @frame[0] * w_delta, @frame[1] * w_delta,
                @frame[2] * h_delta, @frame[3] * h_delta
  end

  def idle
    @block.call self if @block && !@pause
    glutPostRedisplay
  end

  def run(&block)
    @block = block
    glutMainLoop
  end

end
