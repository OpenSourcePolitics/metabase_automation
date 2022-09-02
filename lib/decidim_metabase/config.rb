# frozen_string_literal: true

module DecidimMetabase
  # Config - Contains global configuration from 'config.yml'
  class Config
    attr_reader :databases, :collection_name, :language, :host

    def initialize(hash)
      @databases = databases_to_ary(hash["database"])
      @collection_name = hash["collection_name"]
      @language = hash["language"]
      @host = hash["host"]
    end

    # Creates an array of Databases with methods :
    #   type => Name of cards folder
    #   name => Name of the Metabase database name
    def databases_to_ary(hash)
      hash.map do |key, value|
        Class.new do
          attr_reader :type, :name

          def initialize(type, name)
            @type = type
            @name = name
          end
        end.new(key, value["name"])
      end
    end
  end
end