# Hello
## OpenGL Ruby
### Install
To start working with OpenGL in Ruby you have to install some system packages first

    sudo apt-get install mesa-utils mesa-common-dev freeglut3-dev

And install the following gems glu/glut/opengl

    bundle install

### Bezier
[Simple Bezier curve example](bezier.md)

### Usage example

```ruby
renderer = Render.new
renderer.scene = { objects: objects,
                   types: { TailedObject => { point: ->(o) { o.position }, path: ->(o) { o.path } } } }

physics = Physics.new
renderer.run do
  physics.step renderer.scene[:objects], Time.now.to_f
end
```
 