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

      def local_cards(paths, metabase_collection)
        @cards = paths.map do |path|
          next unless File.directory?(path)

          card = DecidimMetabase::Object::FileSystemCard.new(path)
          card.collection_id = metabase_collection.id
          card.card_exists?(metabase_collection)
          card
        end.compact.sort_by(&:dependencies)

        sort_cards_by_dependencies!
      end

      alias local_cards! local_cards

      private

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/AbcSize
      def sort_cards_by_dependencies
        @cards.each_with_index do |card, index|
          next if card.dependencies.empty?

          deps_ids = []
          card.dependencies.each do |dep|
            deps_id = @cards.index { |elem| elem&.name == dep }
            deps_ids << deps_id unless deps_id.nil?
          end
          next if deps_ids.empty? || index > deps_ids.max

          @cards[index], @cards[deps_ids.max] = @cards[deps_ids.max], @cards[index]
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize

      alias sort_cards_by_dependencies! sort_cards_by_dependencies
    end
  end
end
