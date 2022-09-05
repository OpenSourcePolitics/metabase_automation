# frozen_string_literal: true

module DecidimMetabase
  RSpec.describe Main do
    let(:subject) { described_class.new(message) }
    let(:message) { false }
    let(:configs) { Config.new(configs_yml) }
    let(:metabase_host) { "example.metabase.com" }
    let(:metabase_username) { "user123456" }
    let(:metabase_pwd) { "password123456" }
    let(:env_vars) do
      [
        { "METABASE_HOST" => metabase_host },
        { "METABASE_USERNAME" => metabase_username },
        { "METABASE_PASSWORD" => metabase_pwd }
      ]
    end
    let(:token_db_path) { "./spec/fixtures/token.public" }
    let(:configs_yml) { ::YAML.load_file("./spec/fixtures/config-example.yml") }

    before do
      env_vars.each { |hash| stub_const("ENV", ENV.to_hash.merge(hash)) }
      allow(subject).to receive(:token_db_path).and_return(token_db_path)
    end

    describe "#initialize" do
      it "initializes without printing to stdout" do
        expect do
          subject
        end.not_to output.to_stdout
      end
    end

    describe "#conn" do
      it "defines a new Faraday connection" do
        conn = subject.conn
        expect(conn).to be_a Faraday::Connection
        expect(conn.host).to eq(metabase_host)
        expect(conn.headers["Content-Type"]).to eq("application/json")
      end

      it "alias #conn by #define_connexion!" do
        expect(subject.method(:conn)).to eq(subject.method(:define_connexion!))
      end
    end

    describe "#metabase_url" do
      it "returns the metabase_url" do
        subject.define_connexion!
        expect(subject.metabase_url).to eq("https://example.metabase.com/")
      end

      context "when there is no connexion defined" do
        it "returns empty" do
          expect(subject.metabase_url).to eq("")
        end
      end
    end
    describe "#api_session" do
      it "creates a new api session" do
        expect(subject.api_session).to be_a DecidimMetabase::Api::Session
      end

      it "alias #api_session by #define_api_session!" do
        expect(subject.method(:api_session)).to eq(subject.method(:define_api_session!))
      end

      it "read the stored token" do
        expect(subject.api_session.token).to eq("fake-token-123456")
      end

      context "when token file is not present" do
        before do
          stub_request(:post, "https://example.metabase.com/api/session")
            .with(
              body: {
                "username" => "user123456",
                "password" => "password123456"
              }.to_json,
              headers: {
                "Accept" => "*/*",
                "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                "Content-Type" => "application/json"
              }
            )
            .to_return(status: 200, body: { "id" => "fake-id-123456" }.to_json, headers: {})
          allow(File).to receive(:exist?).with(token_db_path).and_return(false)
          allow(File).to receive(:open).and_call_original
        end

        it "fetch new token" do
          expect(subject.api_session.token).to eq("fake-id-123456")
        end
      end
    end

    describe "#http_request" do
      it "defines a new http requests" do
        expect(subject.http_request).to be_a(DecidimMetabase::HttpRequests)
      end

      it "alias #http_request by #define_http_request!" do
        expect(subject.method(:http_request)).to eq(subject.method(:define_http_request!))
      end
    end

    describe "#api_database" do
      it "defines a new http requests" do
        expect(subject.api_database).to be_a(DecidimMetabase::Api::Database)
      end

      it "alias #api_database by #define_api_database!" do
        expect(subject.method(:api_database)).to eq(subject.method(:define_api_database!))
      end
    end
  end
end
