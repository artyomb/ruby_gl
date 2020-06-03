require 'nokogiri'

class Linkage2
  attr_reader :nodes, :links, :inputs

  def initialize(file_name)
    doc = Nokogiri::XML File.read file_name

    @inputs = []

    @nodes = doc.xpath('//linkage2/connector').map do |node|
      if node.attribute('input').to_s == 'true'
        @inputs << { type: :angle, id: node.attribute('id').to_s.to_i, rpm: node.attribute('rpm').to_s.to_f}
      end
      [node.attribute('id').to_s.to_i, { id: node.attribute('id').to_s.to_i,
                                         anchor: node.attribute('anchor').to_s == 'true',
                                         x: node.attribute('x').to_s.to_f, y: node.attribute('y').to_s.to_f }]
    end.to_h

    @links = doc.xpath('//linkage2/Link').map do |link|
      if link.attribute('actuator').to_s == 'true'
        @inputs << { type: :actuator, id: link.attribute('id').to_s.to_i,
                     startoffset: link.attribute('startoffset').to_s.to_f,
                     throw: link.attribute('throw').to_s.to_f,
                     cpm: link.attribute('cpm').to_s.to_f
        }
      end

      nodes = link.xpath('connector').map { |c| @nodes[c.attribute('id').to_s.to_i] }
      [link.attribute('id').to_s.to_i, { id: link.attribute('id').to_s.to_i, nodes: nodes }]
    end.to_h
  end

  def dimensions
    box = bounding
    [(box[0][0] - box[1][0]).abs, (box[0][1] - box[1][1]).abs]
  end

  def bounding
    x_max = x_min = @nodes.values.first[:x]
    y_max = y_min = @nodes.values.first[:y]
    @nodes.each do |_index, node|
      x_max = [node[:x], x_max].max
      y_max = [node[:y], y_max].max
      x_min = [node[:x], x_min].min
      y_min = [node[:y], y_min].min
    end
    [Vector[x_min, y_min], Vector[x_max, y_max]]
  end
end

# bird = Linkage2.new 'linkage/bird.linkage2'
# p bird.nodes
# p bird.links
