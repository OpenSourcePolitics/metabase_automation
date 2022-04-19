# frozen_string_literal: true

require_relative "decidim_metabase/version"
require_relative "decidim_metabase/api/api"
require_relative "decidim_metabase/api/session"
require_relative "decidim_metabase/api/routes"

module DecidimMetabase
  class Error < StandardError; end
  # Your code goes here...
end
