# frozen_string_literal: true

module DecidimMetabase
  module Object
    # Metabase card
    class Card
      attr_accessor :id, :name, :description, :archived, :collection_position, :table_id, :database_id, :collection_id,
                    :query_type, :creator, :collection, :dataset_query, :need_update, :exist, :resource, :result_metadata

      def initialize(hash, exist = true)
        @id = hash["id"]
        @name = hash["name"]
        @description = hash["description"]
        @archived = hash["archived"]
        @collection_position = hash["collection_position"]
        @table_id = hash["table_id"]
        @database_id = hash["database_id"]
        @collection_id = hash["collection"]["id"]
        @query_type = hash["query_type"]
        @creator = hash["creator"]
        @collection = DecidimMetabase::Object::Collection.new(hash["collection"])
        @dataset_query = hash["dataset_query"]
        @result_metadata = hash["result_metadata"]
        @need_update = false
        @exist = exist
      end

      def creator_email
        @creator_email ||= @creator["email"]
      end

      def query
        @query ||= @dataset_query["native"]["query"]
      end

      def card_exists?(collection)
        target = collection.find_card(name)
        @exist = !(target.nil? || target.name.empty?)
      end

      def switch_actions
        if @exist && @need_update
          :update
        elsif !@exist
          :create
        else
          :up_to_date
        end
      end

      def update_id!(id)
        @id = id.to_i
      end
    end
  end
end
