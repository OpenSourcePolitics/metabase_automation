# frozen_string_literal: true

module DecidimMetabase
  RSpec.describe QueryInterpreter do
    describe "interpret_host" do
      let(:query) { "SELECT * FROM example WHERE HOST=$HOST;" }

      describe "#interpret_host?" do
        let(:subject) { described_class.interpret_host?(query) }

        it "returns true" do
          expect(subject).to be_truthy
        end

        context "when query doesn't contain '$HOST'" do
          let(:query) { "SELECT * FROM example WHERE HOST=host;" }

          it "returns false" do
            expect(subject).to be_falsey
          end
        end
      end

      describe "#interpret_host" do
        let(:subject) { described_class.interpret_host(query, "host.example.com") }

        it "replaces the original query" do
          expect(subject).to eq("SELECT * FROM example WHERE HOST='host.example.com';")
        end
      end
    end

    describe "interpret_language_code" do
      let(:query) { "SELECT * FROM example WHERE LANGUAGE_CODE=$LANGUAGE_CODE;" }

      describe "#interpret_language_code?" do
        let(:subject) { described_class.interpret_language_code?(query) }

        it "returns true" do
          expect(subject).to be_truthy
        end

        context "when query doesn't contain '$HOST'" do
          let(:query) { "SELECT * FROM example WHERE LANGUAGE_CODE=language_code;" }
          it "returns false" do
            expect(subject).to be_falsey
          end
        end
      end

      describe "#interpret_language_code" do
        let(:subject) { described_class.interpret_language_code(query, "fr") }

        it "replaces the original query" do
          expect(subject).to eq("SELECT * FROM example WHERE LANGUAGE_CODE=fr;")
        end
      end
    end

    describe "#interpret?" do
      let(:subject) { described_class.interpret?(query, key) }
      let(:query) { "SELECT {{#table}} FROM example;" }
      let(:key) { "table" }

      it "returns true" do
        expect(subject).to be_truthy
      end

      context "when query doesn't contain interpretable variable" do
        let(:query) { "SELECT * FROM example;" }

        it "returns false" do
          expect(subject).to be_falsey
        end
      end
    end
  end
end
