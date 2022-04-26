# frozen_string_literal: true

module DecidimMetabase
  module Api
    class CollectionNotFound < DecidimMetabase::Api::ResponseError
      def initialize(response = nil, msg = "Collection is not present")
        super(response, msg)
      end
    end

    class Collection
      def initialize(http_request)
        unless http_request.is_a?(DecidimMetabase::HttpRequests)
          raise ::ArgumentError, "Please use DecidimMetabase::HttpRequests while initializing Collection."
        end

        @http_request = http_request
      end

      def collections
        request = @http_request.get("/api/collection")
        body = JSON.parse(request.body)

        @collections = body
      end

      def create_collection!(name)
        request = @http_request.post("/api/collection", {
                                       name: name,
                                       color: "#509AA3",
                                       parent_id: nil,
                                       namespace: nil,
                                       authority_level: nil
                                     })

        JSON.parse(request.body)
      end

      # Find a unique collection from available collections
      def find_by(name = "")
        return if name == "" || name.nil?

        collections&.select { |coll| name == coll["name"] }&.first
      end

      # Find existing collection or create it if not exists
      def find_or_create!(name)
        found = find_by name

        unless found.nil? || found.empty?
          puts "Collection '#{name}' is already existing"
          return found
        end

        puts "Creating collection '#{name}'..."
        create_collection!(name)
      end
    end
  end
end
