# Hello
## OpenGL Ruby

<img src="https://www.jasondavies.com/animated-bezier/full.png" width="400" height="whatever">
 
 ```ruby
renderer = Render.new
renderer.scene = { objects: objects, types: { TailedObject => [:point, :path] } }

physics = Physics.new
renderer.run do
  physics.step renderer.scene[:objects], Time.now.to_f
end
 ```
 