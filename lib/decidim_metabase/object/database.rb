# frozen_string_literal: true

module DecidimMetabase
  module Object

    # Metabase collection
    class Database
      attr_accessor :id, :name, :description

      def initialize(hash)
        @id = hash["id"]
        @name = hash["name"]
        @description = hash["description"]
      end
    end
  end
end
