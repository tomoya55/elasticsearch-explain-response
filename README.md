# Elasticsearch-explain-response

[![Circle CI](https://circleci.com/gh/tomoya55/elasticsearch-explain-response/tree/master.svg?style=svg)](https://circleci.com/gh/tomoya55/elasticsearch-explain-response/tree/master)

Parse Elasticsearch Explain Response and summarize it in a simple way.
This gem is intended for developers working with Elasticsearch to debug search scores
in a easier way.
The current feature is very simple, but any suggestions or feature requests are welcomed.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elasticsearch-explain-response'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install elasticsearch-explain-response
```

## Usage

### Summarize the explanation in one line

```ruby
require 'elasticsearch'
client = Elasticsearch::Client.new
result = client.explain index: "megacorp", type: "employee", id: "1", q: "last_name:Smith"
puts Elasticsearch::API::Response::ExplainResponse.new(result["explanation"]).render_in_line
#=>
1.0 = (1.0(termFreq=1.0)) x 1.0(idf(2/3)) x 1.0(fieldNorm)
```

### Summarize the explanation in lines

```ruby
puts Elasticsearch::API::Response::ExplainResponse.new(result["explanation"]).render
#=>
1.0 = 1.0(fieldWeight)
  1.0 = 1.0(tf(1.0)) x 1.0(idf(2/3)) x 1.0(fieldNorm)
    1.0 = 1.0(termFreq=1.0)
```

### Get the summarized explanation as a Hash

```ruby
puts Elasticsearch::API::Response::ExplainResponse.new(result["explanation"]).result
#=>
{ :score=>0.8467586,
  :type=>"fieldWeight",
  :operator=>"x",
  :operation=>"fieldWeight",
  :children=>
   [{:score=>1.7320508,
     :type=>"tf",
     :operation=>"tf(3.0)",
     :children=>[{:score=>3.0, :type=>"termFreq=3.0", :operation=>"termFreq=3.0"}]},
    {:score=>4.469726, :type=>"idf", :operation=>"idf(382/12305)"},
    {:score=>0.109375, :type=>"fieldNorm(doc=1035)", :operation=>"fieldNorm(doc=1035)"}]}
```

## Contributing

1. Fork it ( https://github.com/tomoya55/elasticsearch-explain-response/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
