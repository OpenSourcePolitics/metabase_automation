# frozen_string_literal: true

RSpec.describe DecidimMetabase::Api::Database do
  let(:subject) { described_class.new(http_request) }

  let(:conn) { Faraday.new { |b| b.adapter(:test, stubs) } }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:token_db_path) { "./spec/fixtures/token.private" }
  let(:http_request) { DecidimMetabase::HttpRequests.new(api_session) }
  let(:api_session) { DecidimMetabase::Api::Session.new(conn, params_h, token_db_path) }
  let(:database_name) { "Rspec database" }

  let(:session_response) { { "id" => new_token } }

  let(:database_response) do
    {
      "data" => [{
        "description" => nil,
        "features" => %w[full-join basic-aggregations standard-deviation-aggregations],
        "name" => database_name,
        "settings" => nil,
        "native_permissions" => "write",
        "cache_ttl" => nil,
        "details" => {
          "host" => "localhost",
          "port" => 5432,
          "dbname" => database_name,
          "user" => "metabase",
          "password" => "**MetabasePass**",
          "ssl" => true,
          "additional-options" => nil,
          "tunnel-enabled" => false
        },
        "is_sample" => false,
        "id" => 19,
        "points_of_interest" => nil
      }]
    }
  end

  let(:token) { "fake-token-123456" }
  let(:new_token) { "new-token-123456" }
  let(:params_h) { { username: "example", password: "password" } }

  before do
    stubs.post("/api/session") do |_env|
      [
        200, { "Content-Type" => "application/json" }, session_response.to_json
      ]
    end
    stubs.get("/api/database") do |_env|
      [
        200, { "Content-Type" => "application/json" }, database_response.to_json
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
      expect do
        subject
      end.to raise_error(::ArgumentError, "Please use DecidimMetabase::HttpRequests while initializing database.")
    end
  end

  describe "#databases" do
    it "returns all databases" do
      expect(subject.databases).to eq(database_response["data"])
      expect(subject.databases).to be_a Array
    end
  end

  describe "#find_by" do
    let(:name) { database_name }

    it "returns target database" do
      expect(subject.find_by(name)).to eq(database_response["data"].first)
    end

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

    context "when database is not found" do
      let(:name) { "Unknown Database" }

      it "raises an error 'DatabaseNotFound'" do
        expect { subject.find_by(name) }.to raise_error DecidimMetabase::Api::DatabaseNotFound
      end
    end
  end
end
