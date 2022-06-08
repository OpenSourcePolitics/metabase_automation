# frozen_string_literal: true

module DecidimMetabase
  module Object

    # Metabase collection
    class Collection
      attr_accessor :authority_level, :description, :archived, :slug, :color, :can_write, :name, :personal_owner_id, :id, :location, :namespace, :cards

      def initialize(hash)
        @authority_level = hash["authority_level"]
        @description = hash["description"]
        @archived = hash["archived"]
        @slug = hash["slug"]
        @color = hash["color"]
        @can_write = hash["can_write"]
        @name = hash["name"]
        @personal_owner_id = hash["personal_owner_id"]
        @id = hash["id"]
        @location = hash["location"]
        @namespace = hash["namespace"]
      end

      def find_card(name)
        @cards.select { |card| card&.name == name }.compact&.first
      end
    end
  end
end
