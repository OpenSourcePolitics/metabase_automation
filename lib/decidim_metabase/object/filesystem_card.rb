# frozen_string_literal: true

module DecidimMetabase
  module Object
    # Metabase card
    class FileSystemCard < Card
      attr_accessor :query

      def initialize(path)
        @path = path
        @to_h = setup!
      end

      def setup!
        return unless File.directory?(@path)
        return unless File.exist? info_path
        return unless File.exist? locales_path

        serialize_to_h
      end

      def dependencies
        @dependencies ||= if no_dependencies?
                            []
                          else
                            yaml_info.dig("query", "info", "meta", "depends_on")
                          end
      end

      def dependencies?
        !yaml_info.dig("query", "info", "meta", "depends_on").nil?
      end

      # TODO: Must be updated once translation enabled
      def name
        @name ||= @path.split("/")[-1].gsub("_", " ").downcase
      end

      def yaml_info
        @yaml_info ||= YAML.load_file info_path
      end

      def yaml_locales
        @yaml_locales ||= YAML.load_file locales_path
      end

      def query
        @query ||= yaml_info["query"]["sql"].chomp
      end

      # Payload for Metabase API
      # Can be merged if variables must be interpreted
      def payload(collection, decidim_db_id, cards)
        payload = base_payload(collection, decidim_db_id)

        dependencies.each do |dep|
          payload.merge!(dependencie_payload(payload, find_card_by(dep, cards)&.id))
        end

        payload
      end

      def find_card_by(name, cards)
        found = cards.select { |card| card.name == name }
        return found.first if found.count == 1

        found.select { |elem| elem.instance_of?(DecidimMetabase::Object::Card) }.first
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

      def no_dependencies?
        yaml_info.dig("query", "info", "meta", "depends_on").nil?
      end

      def locales_path
        "#{@path}/locales/en.yml"
      end

      def info_path
        "#{@path}/info.yml"
      end
    end
  end
end