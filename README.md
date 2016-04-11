# Jekyll::Amazon

Liquid tag for display Amazon Associate Links in Jekyll sites: `{% amazon %}`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jekyll-amazon'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jekyll-amazon

Finally, add the following to your site's `_config.yml`:

```
gems:
 - jekyll-amazon
```

## Usage

Use the tag as follows in your jekyll pages, posts and collections:


```liquid
{% amazon 4083210443 detail %}
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tokzk/jekyll-amazon.

