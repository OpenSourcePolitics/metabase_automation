# frozen_string_literal: true

module DecidimMetabase
  # Source: https://github.com/ruby/tsort/blob/6473bfee9eb96d64980b330f6d3cee543658b9c3/lib/tsort.rb#L239
  class TopologicalSort
    include TSort
    def initialize(g)
      @g = g
    end
    def tsort_each_child(n, &b) @g[n].each(&b) end
    def tsort_each_node(&b) @g.each_key(&b) end
  end
end
