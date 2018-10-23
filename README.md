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

### Initialize the custom explainer

```ruby
require 'elasticsearch'
client = Elasticsearch::Client.new
result = client.explain index: "megacorp", type: "employee", id: "1", q: "last_name:Smith"
custom_explainer = Elasticsearch::API::Response::ExplainResponse.new(result["explanation"])
```

### Summarize the explanation in one line

```ruby
custom_explainer.render_in_line
#=>
1.0 = (1.0(termFreq=1.0)) x 1.0(idf(2/3)) x 1.0(fieldNorm)
```

### Summarize the explanation in lines

```ruby
custom_explainer.render
#=>
1.0 = 1.0(fieldWeight)
  1.0 = 1.0(tf(1.0)) x 1.0(idf(2/3)) x 1.0(fieldNorm)
    1.0 = 1.0(termFreq=1.0)
```

### Customize your rendering

#### Translate your custom scripts

```ruby
custom_painless_script = <<~PAINLESS.delete("\n")
  (
    doc['response_rate'].value > 0.5 &&
    doc['unavailable_until'].empty
  ) ? 1 : 0)
PAINLESS

custom_translator => (lambda do |value|
  if value == 1
    '1/1 Is available and good chance of reply'
  else
    '0/1 Not available or low chance of reply'
  end
end)

script_translation_map = {
  custom_painless_script => custom_translator
}

custom_explainer = Elasticsearch::API::Response::ExplainResponse.new(
  result["explanation"],
  script_translation_map: script_translation_map
)
custom_explainer.render
#=>
0.1 = 0.1(script(Custom script:0/1 Not available or low chance of reply))

```

#### Change basic formatting

```ruby
custom_explainer.render(
  precision: 6  # 6 decimals
)

## Contributing

1. Fork it ( https://github.com/tomoya55/elasticsearch-explain-response/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
