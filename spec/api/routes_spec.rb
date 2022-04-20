# frozen_string_literal: true

RSpec.describe DecidimMetabase::Api::Routes do
  it "has a route prefix" do
    expect(subject::ROUTE_PREFIX).to eq "/api"
  end

  it "has session route" do
    expect(subject::API_SESSION).to eq "/api/session"
  end

  it "has collection index route" do
    expect(subject::API_COLLECTION_INDEX).to eq "/api/collection"
  end

end
