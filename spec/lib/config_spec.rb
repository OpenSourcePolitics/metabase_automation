# frozen_string_literal: true

module DecidimMetabase
  RSpec.describe Config do
    let(:subject) { described_class.new(config_file_yaml) }
    let(:config_file_yaml) { "./spec/fixtures/config-example.yml" }

    describe "#initialize" do
      it "setup!" do
        config = subject

        expect(config.collection_name).to eq("Collection name")
        expect(config.language).to eq("fr")
        expect(config.host).to eq("example.host.com")
        expect(config.databases).to be_a Array
      end

      it "defines a list of config databases" do
        config = subject
        expect(config.databases.first).to respond_to(:type, :name)
        expect(config.databases.last).to respond_to(:type, :name)

        expect(config.databases.first.type).to eq("decidim_cards")
        expect(config.databases.last.type).to eq("matomo_cards")

        expect(config.databases.first.name).to eq("Decidim Cards Database")
        expect(config.databases.last.name).to eq("Matomo Cards Database")
      end

      context "when config file is not defined" do
        before do
          allow(File).to receive(:exist?).with(config_file_yaml).and_return false
        end

        it "raises a ConfigNotFound exception" do
          expect do
            subject
          end.to raise_error(ConfigNotFound)
        end
      end
    end
  end
end
