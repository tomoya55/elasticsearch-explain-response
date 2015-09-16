require 'spec_helper'
require "pry"

describe Elasticsearch::API::Response::ExplainResponse do
  let(:fake_response) do
    fixture_load(:response1)
  end

  describe '.render_in_line' do
    subject do
      described_class.render_in_line(fake_response)
    end

    it "returns summary" do
      expect(subject).not_to be_empty
    end
  end

  describe '.render' do
    subject do
      described_class.render(fake_response)
    end

    it "returns summary" do
      expect(subject).not_to be_empty
    end
  end

  describe "#render_in_line" do
    let(:response) do
      described_class.new(fake_response["explanation"], colorize: false, max: 5, show_values: show_values)
    end

    subject do
      response.render_in_line
    end

    context "with show_values" do
      let(:show_values) do
        true
      end

      it "returns summary of explain in line" do
        expect(subject).to eq("0.05 = ((1.0(idf(2/3)) x 0.43(queryNorm)) x (1.0(tf(1.0)) x 1.0(idf(2/3)) x 0.25(fieldNorm(doc=0))) x 10.0(match(name.raw:smith)) x 0.99(func(updated_at)) x 5.93(script(popularity:\"def val = factor * log(sqrt(doc['popularity'].value) + 1) + 1\" {factor=1.0})) x 1.0(constant) min 3.4e+38) x 0.5(coord(1/2)) x 1.0(queryBoost)")
      end

      context "with fake_response2" do
        let(:fake_response) do
          fixture_load(:response2)
        end

        it "returns summary of explain in line" do
          expect(subject).to eq("887.19 = ((10.0(match(name:hawaii)) x 10.0(match(name:guam)) x 0.7(match(name:\"new caledonia\", new, nueva, caledonia)) x 3.0(match(with_beach:T)) x 0.99(func(updated_at)) x 3.0(match(region_id:[3 TO 3]))) min 3.4e+38) x 1.0(queryBoost)")
        end
      end
    end

    context "with show_values false" do
      let(:show_values) do
        false
      end

      it "returns summary of explain in line" do
        expect(subject).to eq("0.05 = ((1.0(idf(2/3)) x 0.43(queryNorm)) x (1.0(tf(1.0)) x 1.0(idf(2/3)) x 0.25(fieldNorm(doc=0))) x 10.0(match(name.raw)) x 0.99(func(updated_at)) x 5.93(script(popularity)) x 1.0(constant) min 3.4e+38) x 0.5(coord(1/2)) x 1.0(queryBoost)")
      end

      context "with fake_response2" do
        let(:fake_response) do
          fixture_load(:response2)
        end

        it "returns summary of explain in line" do
          expect(subject).to eq("887.19 = ((10.0(match(name)) x 10.0(match(name)) x 0.7(match(name)) x 3.0(match(with_beach)) x 0.99(func(updated_at)) x 3.0(match(region_id))) min 3.4e+38) x 1.0(queryBoost)")
        end
      end
    end
  end

  describe "#render" do
    let(:response) do
      described_class.new(fake_response["explanation"], max: max, colorize: false, plain_score: plain_score, show_values: show_values)
    end

    let(:max) { nil }
    let(:plain_score) { nil }
    let(:show_values) { false }

    subject do
      response.render.lines.map(&:rstrip)
    end

    context "with show_values" do
      let(:show_values) { true }

      it "returns summary of explain in lines" do
        expect(subject).to match_array [
          "0.05 = 0.11 x 0.5(coord(1/2)) x 1.0(queryBoost)",
          "  0.11 = 0.11 min 3.4e+38",
          "    0.11 = 0.11(weight(_all:smith))",
          "      0.11 = 0.11(score)"
        ]
      end

      context "with max = 5" do
        let(:max) { 5 }

        it "returns summary of explain in lines" do
          expect(subject).to match_array([
            "0.05 = 0.11 x 0.5(coord(1/2)) x 1.0(queryBoost)",
            "  0.11 = 0.11 min 3.4e+38",
            "    0.11 = 0.11(weight(_all:smith))",
            "      0.11 = 0.11(score)",
            "        0.11 = 0.43(queryWeight) x 0.25(fieldWeight) x 10.0 x 0.99 x 5.93(script(popularity:\"def val = factor * log(sqrt(doc['popularity'].value) + 1) + 1\" {factor=1.0})) x 1.0(constant)",
            "          0.43 = 1.0(idf(2/3)) x 0.43(queryNorm)",
            "          0.25 = 1.0(tf(1.0)) x 1.0(idf(2/3)) x 0.25(fieldNorm(doc=0))",
            "          10.0 = 10.0 x 1.0(match(name.raw:smith))",
            "          0.99 = 0.99(func(updated_at))"
          ])
        end
      end

      context "with plain_score = true" do
        let(:plain_score) { true }

        it "returns summary of explain in lines" do
          expect(subject).to match_array([
            "0.05 = 0.11 x 0.5(coord(1/2)) x 1.0(queryBoost)",
            "  0.11 = 0.11 min 3.4028235e+38",
            "    0.11 = 0.11(weight(_all:smith))",
            "      0.11 = 0.11(score)"
          ])
        end
      end
    end
  end

  describe "colorization" do
    let(:response) do
      described_class.new(fake_response["explanation"])
    end

    subject do
      response.render
    end

    it "includes ansi color codes" do
      expect(subject).to include("\e[35;1m0")
      expect(subject).to include("\e[0m")
    end
  end
end
