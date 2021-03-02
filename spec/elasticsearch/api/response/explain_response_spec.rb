require 'spec_helper'

describe Elasticsearch::API::Response::ExplainResponse do
  let(:fake_response) do
    fixture_load(:response1)
  end

  describe '.render_in_line' do
    context "with explain" do
      it "returns summary" do
        result = described_class.render_in_line(fake_response)
        expect(result).not_to be_empty
      end
    end

    context "with empty explain" do
      it "returns summary" do
        result = described_class.render_in_line({}, colorize: false)
        expect(result).to eq("0.0 = ")
      end
    end

    context "with block" do
      it "changes the tree before rendering" do
        result = described_class.render_in_line(fake_response, colorize: false) do |tree|
          tree.children = tree.children[0..1]
          tree
        end
        expect(result).to eq("0.05 = (0.11(score) x 0.5(coord(1/2)))")
      end
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
        expect(subject).to eq("0.05 = (1.0(idf(2/3)) x 0.43(queryNorm)) x (1.0(tf(1.0)) x 1.0(idf(2/3)) x 0.25(fieldNorm(doc=0))) x 10.0(match(name.raw:smith)) x 0.99(func(updated_at)) x 5.93(script(popularity:\"def val = factor * log(sqrt(doc['popularity'].value) + 1) + 1\" {factor=1.0})) x 1.0(constant) x 0.5(coord(1/2)) x 1.0(queryBoost)")
      end

      context "with fake_response2" do
        let(:fake_response) do
          fixture_load(:response2)
        end

        it "returns summary of explain in line" do
          expect(subject).to eq("887.19 = (10.0(match(name:hawaii)) x 10.0(match(name:guam)) x 0.7(match(name:\"new caledonia\", new, nueva, caledonia)) x 3.0(match(with_beach:T)) x 0.99(func(updated_at)) x 3.0(match(region_id:[3 TO 3])))")
        end
      end
    end

    context "with show_values false" do
      let(:show_values) do
        false
      end

      it "returns summary of explain in line" do
        expect(subject).to eq("0.05 = (1.0(idf(2/3)) x 0.43(queryNorm)) x (1.0(tf(1.0)) x 1.0(idf(2/3)) x 0.25(fieldNorm(doc=0))) x 10.0(match(name.raw)) x 0.99(func(updated_at)) x 5.93(script(popularity)) x 1.0(constant) x 0.5(coord(1/2)) x 1.0(queryBoost)")
      end

      context "with fake_response2" do
        let(:fake_response) do
          fixture_load(:response2)
        end

        it "returns summary of explain in line" do
          expect(subject).to eq("887.19 = (10.0(match(name)) x 10.0(match(name)) x 0.7(match(name)) x 3.0(match(with_beach)) x 0.99(func(updated_at)) x 3.0(match(region_id)))")
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
          "    0.11 = 0.11(weight(_all:smith))",
          "      0.11 = 0.11(score)"
        ]
      end

      context "with max = 5" do
        let(:max) { 5 }

        it "returns summary of explain in lines" do
          expect(subject).to match_array([
            "0.05 = 0.11 x 0.5(coord(1/2)) x 1.0(queryBoost)",
            "    0.11 = 0.11(weight(_all:smith))",
            "      0.11 = 0.11(score)",
            "        0.11 = 0.43(queryWeight) x 0.25(fieldWeight) x 10.0(match(name.raw:smith)) x 0.99(func(updated_at)) x 5.93(script(popularity:\"def val = factor * log(sqrt(doc['popularity'].value) + 1) + 1\" {factor=1.0})) x 1.0(constant)",
            "          0.43 = 1.0(idf(2/3)) x 0.43(queryNorm)",
            "          0.25 = 1.0(tf(1.0)) x 1.0(idf(2/3)) x 0.25(fieldNorm(doc=0))",
            "          10.0 = 10.0(match(name.raw:smith))",
            "          0.99 = 0.99(func(updated_at))"
          ])
        end
      end

      context "with plain_score = true" do
        let(:plain_score) { true }

        it "returns summary of explain in lines" do
          expect(subject).to match_array([
            "0.05 = 0.11 x 0.5(coord(1/2)) x 1.0(queryBoost)",
            "    0.11 = 0.11(weight(_all:smith))",
            "      0.11 = 0.11(score)"
          ])
        end
      end
    end
  end

  describe "#render_as_hash" do
    let(:response) do
      described_class.new(fake_response["explanation"], colorize: false)
    end

    subject do
      response.render_as_hash
    end

    it "returns the explain response as a hash" do
      expect(subject).to be_a_kind_of(Hash)
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

  describe 'script translation map' do
    let(:fake_response) do
      fixture_load(:response_with_named_scripts)
    end
    let(:custom_script) do
      <<~PAINLESS.delete("\n")
        (doc['response_rate'].value > 0.5 &&
         doc['unavailable_until'].empty
        ) ? 1 : 0)
      PAINLESS
    end
    let(:script_translation_map) do
      {
        custom_script => (lambda do |value|
          if value == 1
            '1/1 Is available and good chance of reply'
          else
            '0/1 Not available or low chance of reply'
          end
        end)
      }
    end

    let(:response) do
      described_class.new(fake_response["explanation"],
        colorize: false,
        script_translation_map: script_translation_map
      )
    end

    subject do
      response.render
    end

    context 'when the ES value indicates a low response/unavailable' do
      let(:explanation) { fake_response['explanation'] }

      it 'translate the script using the unavailable text' do
        expect(subject).to include('0.0(script(Custom script:0/1 Not available or low chance of reply))')
      end
    end

    context 'when the ES value indicates a good response rate + availability' do
      let(:explanation) { fake_response['explanation'] }

      it 'translate the script using the available text' do
        expect(subject).to include('1.0(script(Custom script:1/1 Is available and good chance of reply))')
      end
    end
  end
end
