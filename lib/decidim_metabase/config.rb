# frozen_string_literal: true

module DecidimMetabase
  # ConfigNotFound : Exception - Raised when required file 'config.yml' is not found
  class ConfigNotFound < StandardError
    def initialize(msg = "File 'config.yml' not found. Ensure you copied 'config.yml.example' file.")
      super
    end
  end

  # Config - Contains global configuration from 'config.yml'
  class Config
    attr_reader :databases, :collection_name, :language, :host

    def initialize
      setup!
    end

    def setup!
      hash = load_file

      @databases = databases_to_ary(hash["database"])
      @collection_name = hash["collection_name"]
      @language = hash["language"]
      @host = hash["host"]

      self
    end

    # Load main config YAML
    def load_file
      raise ConfigNotFound unless File.exist?("config.yml")

      YAML.load_file("config.yml")
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
