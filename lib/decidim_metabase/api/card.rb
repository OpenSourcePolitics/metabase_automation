# frozen_string_literal: true

module DecidimMetabase
  module Api
    # rubocop:disable Metrics/ClassLength
    # Card mixes decidim_cards and Metabase card
    # It allows to take in account cards inter-dependencies
    class Card
      attr_accessor :to_h, :path, :id, :need_update, :exist

      def initialize(path)
        @path = path
        @need_update = false
        @exist = false
        @to_h = setup!
      end

      def setup!
        return unless File.directory?(path)
        return unless File.exist? info_path
        return unless File.exist? locales_path

        serialize_to_h
      end

      # Replace query with interpreted values based on previous cards
      def interpreter!(configs, cards)
        interpret_host(configs["host"])
        @organization_payload = interpret(cards, "organizations")
        @components_payload = interpret(cards, "components")
        @forms_payload = interpret(cards, "forms")
      end

      def update_id!(id)
        @id = id.to_i
      end

      def invalid?
        @to_h.nil?
      end

      def name
        @path.split("/")[-1].downcase
      end

      def yaml_info
        @yaml_info ||= YAML.load_file info_path
      end

      def yaml_locales
        @yaml_locales ||= YAML.load_file locales_path
      end

      def dependencies
        @dependencies ||= if no_dependencies?
                            []
                          else
                            yaml_info.dig("query", "info", "meta", "depends_on")
                          end
      end

      def no_dependencies?
        yaml_info.dig("query", "info", "meta", "depends_on").nil?
      end

      def query
        @query ||= yaml_info["query"]["sql"].chomp
      end

      def interpreted_query
        @interpreted_query ||= query
      end

      # Payload for Metabase API
      # Can be merged if variables must be interpreted
      def payload(collection, decidim_db_id, cards)
        payload = base_payload(collection, decidim_db_id)

        if @organization_payload
          target = find_card_by("organizations", cards)
          payload.merge!(dependencie_payload(payload, target.id))
        end

        if @components_payload
          target = find_card_by("components", cards)
          payload.merge!(dependencie_payload(payload, target.id))
        end

        if @forms_payload
          target = find_card_by("forms", cards)
          payload.merge!(dependencie_payload(payload, target.id))
        end

        payload
      end

      def dependencie_payload(payload, id)
        uuid = SecureRandom.uuid.to_s

        payload[:dataset_query]["native"]["template-tags"] = {
          "##{id}" => {
            "id" => uuid,
            "name" => "##{id}",
            "display-name" => "##{id}",
            "type" => "card",
            "card-id" => id
          }
        }
      end

      # rubocop:disable Metrics/MethodLength
      def base_payload(collection, decidim_db_id)
        {
          collection_id: collection.id,
          name: yaml_locales["name"],
          display: "table",
          dataset: true,
          dataset_query: {
            "type" => "native",
            "native" => {
              "query" => query,
              "filter" => {}
            },
            "database" => decidim_db_id
          },
          visualization_settings: {
            "table.cell_column" => "id"
          }
        }
      end
      # rubocop:enable Metrics/MethodLength

      private

      def find_card_by(name, cards)
        cards.select { |card| card.name == name }.first
      end

      def interpret_host?
        query.match?(/\$HOST/)
      end

      def interpret_host(host)
        return unless interpret_host?

        query.gsub!("$HOST", "'#{host}'")
      end

      def interpret?(key)
        query.include?("{{##{key}}}")
      end

      def interpret(cards, key)
        return false unless interpret?(key)

        target = find_card_by(key, cards)
        unless target.respond_to?(:id) && target&.id.is_a?(Integer)
          puts "ID not found for '#{name}'"
          return false
        end

        query.gsub!("{{##{key}}}", "{{##{target&.id}}}")
        true
      end

      def locales_path
        "#{@path}/locales/en.yml"
      end

      def info_path
        "#{@path}/info.yml"
      end

      def serialize_to_h
        {
          name => {
            "path" => @path,
            "yaml_info" => yaml_info,
            "yaml_locales" => yaml_locales
          },
          "depends_on" => dependencies
        }
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
