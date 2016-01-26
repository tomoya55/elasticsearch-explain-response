require "spec_helper"

describe Elasticsearch::API::Response::ExplainTrimmer do
  describe "#trim" do
    context "with function score node" do
      let(:json) do
        {"value"=>100.0,
        "description"=>"function score, product of:",
        "details"=>
         [{"value"=>1.0,
           "description"=> "match filter: QueryWrapperFilter(title:paris)"},
          {"value"=>100.0,
           "description"=>"product of:",
           "details"=>[
             {"value"=>1.0, "description"=>"constant score 1.0 - no function provided"},
             {"value"=>100.0, "description"=>"weight"}
            ]}
          ]
         }
      end

      it "trims function score node" do
        tree = Elasticsearch::API::Response::ExplainParser.new.parse(json)
        result = Elasticsearch::API::Response::ExplainTrimmer.new.trim(tree)
        expect(result.render_as_hash).to eq(
          score: 100.0,
          type: "match",
          operation: "match",
          field: "title",
          value: "paris"
        )
      end
    end

    context "with boost node" do
      let(:json) do
        { "value" => 10,
          "description"=>"function score, product of:",
          "details"=> [
            { "value"=>1, "description"=>"match filter: QueryWrapperFilter(name.raw:smith)"},
            { "value"=>10, "description"=>"static boost factor",
              "details"=>[
                {"value"=>10, "description"=>"boostFactor"}
              ]
            }
          ]
        }
      end

      it "trims boost node" do
        tree = Elasticsearch::API::Response::ExplainParser.new.parse(json)
        result = Elasticsearch::API::Response::ExplainTrimmer.new.trim(tree)
        expect(result.render_as_hash).to eq(
          score: 10,
          type: "match",
          operation: "match",
          field: "name.raw",
          value: "smith"
        )
      end
    end
  end
end
