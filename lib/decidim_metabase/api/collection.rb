module DecidimMetabase
  module Api
    class CollectionNotFound < DecidimMetabase::Api::ResponseError
      def initialize(response = nil, msg = "Collection is not present")
        super(response, msg)
      end
    end

    class Collection
      def initialize(http_request)
        @http_request = http_request
      end

      def collections
        request = @http_request.get("/api/collection")
        body = JSON.parse(request.body)

        @collections = body
      end

      def create_collection!(name)
        request = @http_request.post("/api/collection",  {
          name: name,
          color: "#509AA3",
          parent_id: nil,
          namespace: nil,
          authority_level: nil
        })
        body = JSON.parse(request.body)

        body["data"]
      end

      def find_by(name = "")
        return if name == "" || name.nil?

        collections&.select { |coll| name == coll["name"] }&.first
      end

      def find_or_create!(name)
        found = find_by name
        return found unless found.nil? || found.empty?

        puts "Creating collection '#{name}'..."
        create_collection!(name)
      end
    end
  end
end
