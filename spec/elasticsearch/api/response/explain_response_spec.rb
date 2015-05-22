require 'spec_helper'
require "pry"

describe Elasticsearch::API::Response::ExplainResponse do
  let(:fake_response) do
    fixture_load(:response1)
  end

  describe '.render_in_line' do
    subject do
      pending
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
      described_class.new(fake_response["explanation"], colorize: false)
    end

    before do
      pending
      response.diable_colorization
    end

    it "returns summary of explain in line" do
      expect(subject).to eq("0.05 = (0.43(queryWeight) x 0.25(fieldWeight) x 10.0) x 0.5(coord(1/2)) x 1.0(queryBoost)")
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
      expect(subject).to eq [
        "0.05 = 0.11 x 0.5(coord(1/2)) x 1.0(queryBoost)",
        "  0.11 = 0.11(weight(_all:smith))",
        "    0.11 = 0.11(score)",
        "      0.11 = 0.43(queryWeight) x 0.25(fieldWeight) x 10.0"
      ]
    end

    context "with max = 4" do
      let(:max) { 4 }

      it "returns summary of explain in lines" do
        expect(subject).to eq [
          "0.05 = 0.11 x 0.5(coord(1/2)) x 1.0(queryBoost)",
          "  0.11 = 0.11(weight(_all:smith))",
          "    0.11 = 0.11(score)",
          "      0.11 = 0.43(queryWeight) x 0.25(fieldWeight) x 10.0",
          "        0.43 = 1.0(idf(2/3)) x 0.43(queryNorm)",
          "        0.25 = 1.0(tf(1.0)) x 1.0(idf(2/3)) x 0.25(fieldNorm)",
          "        10.0 = 1.0(match(name.raw:smith))) x 10.0(boost)"
        ]
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
