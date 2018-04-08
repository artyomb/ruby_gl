# <img src="https://www.jasondavies.com/animated-bezier/full.png" width="600" height="whatever">

```ruby
class Vector
  def lerp(t);  self end
end

class Array
  def lerp(t); first.lerp(t) * (1.0 - t) + last.lerp(t) * t  end
  def to_bi_tree
    return self if size == 2
    result = []
    each_index do |index|
      next if index == 0
      result << [self[index-1], self[index]]
    end
    result.to_bi_tree
  end
end

points = [Vector[10, 10], Vector[210, 10], Vector[200, 250], Vector[400, 10]]
bezier_curve = points.to_bi_tree

path = 10.times.map { |index| bezier_curve.lerp(index.to_f / (10 - 1)) }
```