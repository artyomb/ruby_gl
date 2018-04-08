# <img src="https://www.jasondavies.com/animated-bezier/full.png" width="600" height="whatever">

```ruby
points = [Vector[10, 10], Vector[210, 10], Vector[200, 250], Vector[400, 10]]
bezier_curve = points.to_bi_tree

path =   10.times.map { |index| bezier_curve.lerp(index.to_f / (10 - 1)) }
```