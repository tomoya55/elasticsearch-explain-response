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
      described_class.new(fake_response["explanation"], colorize: false, max: 4)
    end

    subject do
      response.render_in_line
    end

    it "returns summary of explain in line" do
      expect(subject).to eq("0.05 = ((0.43(queryWeight) x 0.25(fieldWeight) x 10.0 x 0.99) min 3.4e+38) x 0.5(coord(1/2)) x 1.0(queryBoost)")
    end

    context "with fake_response2" do
      let(:fake_response) do
        fixture_load(:response2)
      end

      it "returns summary of explain in line" do
        expect(subject).to eq("887.19 = ((10.0(match(name:hawaii)) x 10.0(match(name:guam)) x 3.0(match(with_beach:T)) x 0.99(func(updated_at)) x 3.0(match(region_id:[3 TO 3]))) min 3.4e+38) x 1.0(queryBoost)")
      end
    end
  end

  describe "#render" do
    let(:response) do
      described_class.new(fake_response["explanation"], max: max, colorize: false)
    end

    let(:max) { nil }

    subject do
      response.render.lines.map(&:rstrip)
    end

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
          "        0.11 = 0.43(queryWeight) x 0.25(fieldWeight) x 10.0 x 0.99",
          "          0.43 = 1.0(idf(2/3)) x 0.43(queryNorm)",
          "          0.25 = 1.0(tf(1.0)) x 1.0(idf(2/3)) x 0.25(fieldNorm(doc=0))",
          "          10.0 = 10.0 x 1.0(match(name.raw:smith))",
          "          0.99 = 0.99(func(updated_at))"
        ])
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
