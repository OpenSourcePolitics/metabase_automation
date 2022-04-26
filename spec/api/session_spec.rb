# frozen_string_literal: true

RSpec.describe DecidimMetabase::Api::Session do
  let(:subject) { described_class.new(conn, params_h, token_db_path) }

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:conn) { Faraday.new { |b| b.adapter(:test, stubs) } }
  let(:token_db_path) { "./spec/fixtures/token.public" }
  let(:http_response) { { "id" => new_token } }
  before do
    stubs.post("/api/session") do |_env|
      [
        200, { "Content-Type" => "application/json" }, http_response.to_json
      ]
    end

    Faraday.default_connection = conn
    allow(File).to receive(:exist?).with(token_db_path).and_return(false)
  end

  after do
    Faraday.default_connection = nil
    File.write(token_db_path, token)
  end

  let(:token) { "fake-token-123456" }
  let(:new_token) { "new-token-123456" }
  let(:params_h) { { username: "example", password: "password" } }

  it "returns a new token" do
    expect(subject.token).to eq(new_token)
    expect(File.read(token_db_path)).to eq(new_token)
  end

  context "when HTTP response is empty" do
    let(:http_response) { "Error occured" }

    it "raises an API::ResponseError" do
      expect { subject.token }.to raise_error(DecidimMetabase::Api::ResponseError, "Error occured in Metabase response")
    end
  end

  context "when HTTP response is nil" do
    let(:http_response) { nil }

    it "raises an API::ResponseError" do
      expect { subject.token }.to raise_error(DecidimMetabase::Api::ResponseError, "Error occured in Metabase response")
    end
  end

  context "when returned token is not present" do
    let(:http_response) { { "id" => nil } }

    it "raises an Api::TokenNotFound error" do
      expect { subject.token }.to raise_error(DecidimMetabase::Api::TokenNotFound, "Token not found in response")
    end
  end

  context "when token is already stored locally" do
    let(:token_db_path) { "spec/fixtures/token.public" }

    before do
      allow(File).to receive(:exist?).with(token_db_path).and_return(true)
    end

    it "reads token from DB file" do
      expect(subject.token).to eq(token)
    end
  end

  describe "session_request_header" do
    it "interpolates token with session header" do
      expect(subject.session_request_header).to eq("X-Metabase-Session" => new_token)
    end
  end
end
