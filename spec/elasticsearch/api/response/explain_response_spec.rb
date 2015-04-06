require 'spec_helper'

describe Elasticsearch::API::Response::ExplainResponse do
  let(:fake_response) do
    fixture_load(:response1)
  end

  describe "#render_in_line" do
    let(:response) do
      described_class.new(fake_response["explanation"])
    end

    subject do
      response.render_in_line
    end

    before do
      response.diable_colorization
    end

    it "returns summary of explain in line" do
      expect(subject).to eq("0.05 = (0.43(queryWeight) x 0.25(fieldWeight)) x 0.5(coord(1/2))")
    end
  end

  describe "#render" do
    let(:response) do
      described_class.new(fake_response["explanation"])
    end

    subject do
      response.render
    end

    before do
      response.diable_colorization
    end

    it "returns summary of explain in lines" do
      expect(subject).to eq [
        "0.05 = 0.11 x 0.5(coord(1/2))",
        "  0.11 = 0.11(_all:smith)",
        "    0.11 = 0.11(score)",
        "      0.11 = 0.43(queryWeight) x 0.25(fieldWeight)"
      ]
    end
  end
end
