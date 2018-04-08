# Hello
## OpenGL Ruby
### Install
    sudo apt-get install mesa-utils mesa-common-dev freeglut3-dev
    bundle install

<img src="https://www.jasondavies.com/animated-bezier/full.png" width="600" height="whatever">

 ### Usage example

 ```ruby
renderer = Render.new
renderer.scene = { objects: objects, types: { TailedObject => [:point, :path] } }

physics = Physics.new
renderer.run do
  physics.step renderer.scene[:objects], Time.now.to_f
end
 ```
 