# frozen_string_literal: true

module DecidimMetabase
  # Source: https://github.com/ruby/tsort/blob/6473bfee9eb96d64980b330f6d3cee543658b9c3/lib/tsort.rb#L239
  class TopologicalSort
    include TSort
    def initialize(hash)
      @hash = hash
    end

    def tsort_each_child(node, &block)
      @hash[node].each(&block)
    end

    def tsort_each_node(&block)
      @hash.each_key(&block)
    end
  end
end
