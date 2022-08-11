# frozen_string_literal: true

module DecidimMetabase
  module Object
    # Metabase card
    class FileSystemCard < Card
      attr_accessor :query, :payload

      def initialize(path, locale = "en")
        @path = path
        @locale = locale
        @to_h = setup!
      end

      def cards_name
        @path.split("/")[2]
      end

      def setup!
        return unless File.directory?(@path)
        return unless File.exist? info_path

        @locale = "en" unless File.exist? locales_path

        @resource = yaml_info["resource"]
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

      def name
        @name ||= yaml_locales["name"]
      end

      def yaml_info
        @yaml_info ||= YAML.load_file info_path
      end

      def yaml_locales
        @yaml_locales ||= YAML.load_file locales_path
      end

      # rubocop:disable Lint/DuplicateMethods
      def query
        @query ||= yaml_info["query"]["sql"].chomp
      end
      # rubocop:enable Lint/DuplicateMethods

      # Payload for Metabase API
      # Can be merged if variables must be interpreted
      def build_payload(collection, decidim_db_id, cards)
        payload = base_payload(collection, decidim_db_id)

        dependencies.each do |dep|
          payload[:dataset_query]["native"]["template-tags"] ||= {}
          payload[:dataset_query]["native"]["template-tags"].merge!(dependencie_payload(find_card_by(dep, cards)&.id))
        end

        @payload = payload
      end

      alias build_payload! build_payload

      def find_card_by(name, cards)
        found = cards.select { |card| card.resource == name }
        return found.first if found.count == 1

        found.select { |elem| elem.instance_of?(DecidimMetabase::Object::Card) }.first
      end

      def dependencie_payload(id)
        uuid = SecureRandom.uuid.to_s

        {
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
        "#{@path}/locales/#{@locale}.yml"
      end

      def info_path
        "#{@path}/info.yml"
      end
    end
  end
end
