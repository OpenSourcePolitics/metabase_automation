# frozen_string_literal: true

RSpec.describe DecidimMetabase::Api::Collection do
  let(:subject) { described_class.new(http_request) }

  let(:conn) { Faraday.new { |b| b.adapter(:test, stubs) } }
  let(:api_session) { DecidimMetabase::Api::Session.new(conn, params_h, token_db_path) }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:token_db_path) { "./spec/fixtures/token.private" }
  let(:http_request) { DecidimMetabase::HttpRequests.new(conn, api_session) }
  let(:session_response) { { "id" => new_token } }
  let(:collection_name) { "Rspec collection" }
  let(:collection_response) do
    {
      "authority_level" => nil, "description" => nil, "archived" => false, "slug" => "rspec_collection", "color" => "#509AA3", "name" => "Rspec collection", "personal_owner_id" => nil, "id" => 1, "location" => "/", "namespace" => nil
    }
  end

  let(:collection_rspec) do
    { "authority_level" => nil, "name" => "Rspec collection", "id" => "root", "parent_id" => nil, "effective_location" => nil, "effective_ancestors" => [], "can_write" => true }
  end
  let(:collections_response) do
    [
      collection_rspec
    ]
  end

  let(:token) { "fake-token-123456" }
  let(:new_token) { "new-token-123456" }
  let(:params_h) { { username: "example", password: "password" } }

  before do
    stubs.post('/api/session') do |_env|
      [
        200, { "Content-Type" => "application/json" }, session_response.to_json
      ]
    end
    stubs.post('/api/collection') do |_env|
      [
        200, { "Content-Type" => "application/json" }, collection_response.to_json
      ]
    end
    stubs.get('/api/collection') do |_env|
      [
        200, { "Content-Type" => "application/json" }, collections_response.to_json
      ]
    end

    Faraday.default_connection = conn
    allow(File).to receive(:exists?).with(token_db_path).and_return(false)
  end

  after do
    Faraday.default_connection = nil
    File.write(token_db_path, token)
  end

  context "when http_request is not an HttpRequest" do
    let(:http_request) { "Not a DecidimMetabase::HttpRequests" }

    it "doesn't initializes" do
      expect { subject }.to raise_error(::ArgumentError, "Please use DecidimMetabase::HttpRequests while initializing Collection.")
    end
  end

  describe "#create_collection!" do
    it "creates a new collection" do
      expect(subject.create_collection!(collection_name)).to eq collection_response
    end
  end

  describe "#collections" do
    it "fetch existing collections" do
      expect(subject.collections).to eq collections_response
    end
  end

  describe "#find_by" do
    let(:name) { "Rspec collection" }
    context "when name is empty" do
      let(:name) { "" }

      it "returns nil" do
        expect(subject.find_by(name)).to be_nil
      end
    end

    context "when name is nil" do
      let(:name) { nil }

      it "returns nil" do
        expect(subject.find_by(name)).to be_nil
      end
    end

    it "returns collection" do
      expect(subject.find_by(name)).to eq collection_rspec
    end
  end

  describe "#find_or_create!" do
    let(:name) { "Rspec collection" }

    context "when collection exists" do
      it "returns the collection" do
        expect($stdout).to receive(:puts).with("Collection '#{name}' is already existing")
        expect(subject.find_or_create!(name)).to eq(collection_rspec)
      end
    end

    context "when collection does not exist" do
      let(:name) { "Unknown collection" }
      it "creates a new collection" do
        expect($stdout).to receive(:puts).with("Creating collection '#{name}'...")
        expect(subject.find_or_create!(name)).to eq collection_response
      end
    end
  end
end
