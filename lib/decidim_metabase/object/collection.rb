# frozen_string_literal: true

module DecidimMetabase
  module Object
    # Metabase collection
    class Collection
      attr_accessor :authority_level, :description, :archived, :slug, :color, :can_write, :name, :personal_owner_id,
                    :id, :location, :namespace, :cards

      # rubocop:disable Metrics/MethodLength
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
      # rubocop:enable Metrics/MethodLength

      def find_card(name)
        @cards.select { |card| card&.name == name }.compact&.first
      end

      # Populates @cards array from API cards index response
      def cards_from(api_cards)
        @cards = api_cards.map do |card|
          next if card["collection"].nil? || card["collection"].empty?

          obj = DecidimMetabase::Object::Card.new(card, false)
          next unless obj&.collection_id == @id

          obj
        end.compact
      end

      alias cards_from! cards_from

      def local_cards(paths, metabase_collection, locale)
        cards = paths.map do |path|
          next unless File.directory?(path)

          card = DecidimMetabase::Object::FileSystemCard.new(path, locale)
          card.collection_id = metabase_collection.id
          card.card_exists?(metabase_collection)
          card
        end.compact

        @cards ||= []
        @cards += cards
        sort_cards_by_dependencies!
      end
      alias local_cards! local_cards

      def define_resource(collection)
        @cards.each do |card|
          found = collection.find_card(card.name)
          card.resource = found.resource unless found.nil?
        end
      end

      private

      def sort_cards_by_dependencies
        cards_graph = {}
        @cards.each { |card| cards_graph[card.resource] = card.dependencies }

        topo_sort = DecidimMetabase::TopologicalSort.new(cards_graph).tsort
        @cards = topo_sort.map { |resource| @cards.select { |card| card&.resource == resource }.compact&.first }
      end

      alias sort_cards_by_dependencies! sort_cards_by_dependencies
    end
  end
end
