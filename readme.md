# Hello
## OpenGL Ruby
### Install
To start working with OpenGL in Ruby you have to install some system packages first

    sudo apt-get install mesa-utils mesa-common-dev freeglut3-dev

And install the following gems glu/glut/opengl

    bundle install

### Bezie
[Simple Bezie curve eaxample](bezie.md)

### Usage example

 ```ruby
renderer = Render.new
renderer.scene = { objects: objects, types: { TailedObject => [:point, :path] } }

physics = Physics.new
renderer.run do
  physics.step renderer.scene[:objects], Time.now.to_f
end
 ```
 