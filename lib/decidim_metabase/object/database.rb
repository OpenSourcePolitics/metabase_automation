# frozen_string_literal: true

module DecidimMetabase
  module Object
    # Metabase collection
    class Database
      attr_accessor :id, :name, :description, :type

      def initialize(hash, type)
        @id = hash["id"]
        @name = hash["name"]
        @description = hash["description"]
        @type = type
      end
    end
  end
end
