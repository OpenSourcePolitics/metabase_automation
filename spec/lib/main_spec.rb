# frozen_string_literal: true

module DecidimMetabase
  RSpec.describe Main do
    let(:subject) { described_class.new(message) }
    let(:message) { false }
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

      context "when message is set to true" do
        let(:message) { true }
        it "initializes and prints to stdout" do
          expect do
            subject
          end.to output.to_stdout
        end
      end
    end

    describe "#conn" do
      it "defines a new Faraday connection" do
        conn = subject.conn
        expect(conn).to be_a Faraday::Connection
        expect(conn.host).to eq(metabase_host)
        expect(conn.headers["Content-Type"]).to eq("application/json")
      end

      it "alias #conn by #connexion!" do
        expect(subject.method(:conn)).to eq(subject.method(:connexion!))
      end
    end

    describe "#api_session" do
      it "creates a new api session" do
        expect(subject.api_session).to be_a DecidimMetabase::Api::Session
      end

      it "alias #api_session by #api_session!" do
        expect(subject.method(:api_session)).to eq(subject.method(:api_session!))
      end

      it "read the stored token" do
        expect(subject.api_session.token).to eq("fake-token-123456")
      end

      context "when token file is not present" do
        before do
          stub_request(:post, "https://example.metabase.com/api/session").
            with(
              body: {
                "username" => "user123456",
                "password" => "password123456"
              }.to_json,
              headers: {
                'Accept'=>'*/*',
                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'Content-Type'=>'application/json',
              }).
            to_return(status: 200, body: { "id" => "fake-id-123456" }.to_json, headers: {})
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

      it "alias #http_request by #http_request!" do
        expect(subject.method(:http_request)).to eq(subject.method(:http_request!))
      end
    end

    describe "#api_database" do
      it "defines a new http requests" do
        expect(subject.api_database).to be_a(DecidimMetabase::Api::Database)
      end

      it "alias #api_database by #api_database!" do
        expect(subject.method(:api_database)).to eq(subject.method(:api_database!))
      end
    end

    describe "#load_databases!" do
      it "returns an array of Hash" do
        sub = subject
        sub.configs = configs_yml
        sub.load_databases!

        expect(sub.db_registry).to eq([
                                        { "cards" => "decidim_cards", "db_name" => "Decidim Cards Database" },
                                        { "cards" => "matomo_cards", "db_name" => "Matomo Cards Database" }
                                      ])
        expect(sub.databases).to eq([
                                      { "cards" => "decidim_cards", "db_name" => "Decidim Cards Database" },
                                      { "cards" => "matomo_cards", "db_name" => "Matomo Cards Database" }
                                    ])
      end
    end

    describe "#find_db_for" do
      let(:sub) do
        sub = subject
        sub.configs = configs_yml
        sub.load_databases!
        sub
      end

      let(:card) { DecidimMetabase::Object::FileSystemCard.new("./spec/fixtures/cards/decidim_cards/organizations") }

      it "returns the database related to card type" do
        expect(sub.find_db_for(card)).to eq("Decidim Cards Database")
      end
    end
  end
end
