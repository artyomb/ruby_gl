# <img src="https://www.jasondavies.com/animated-bezier/full.png" width="600" height="whatever">

[bezier.rb](bezier.rb)

```ruby
class Vector
  def lerp(t);  self end
end

class Array
  def lerp(t); first.lerp(t) * (1.0 - t) + last.lerp(t) * t  end
  
  def to_bi_tree
    size == 2 ? self :
    each_index.map do |index|
      [self[index], self[index + 1]]
    end[0...-1].to_bi_tree
  end
end

p [0, 1].to_bi_tree # [0, 1]
p [0, 1, 2].to_bi_tree # [[0, 1], [1, 2]]
p [0, 1, 2, 3].to_bi_tree # [[[0, 1], [1, 2]], [[1, 2], [2, 3]]]

points = [Vector[10, 10], Vector[210, 10], Vector[200, 250], Vector[400, 10]]
bezier_curve = points.to_bi_tree

path = Array.new(steps) { |index| bezier_curve.lerp(index.to_f / (steps - 1)) }
```