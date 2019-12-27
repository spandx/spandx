# Spandx

A ruby API for interacting with the https://spdx.org software license catalogue.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'spandx'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install spandx

## Usage

To fetch the latest version of the catalogue data from [SPDX](https://spdx.org/licenses/licenses.json).

```ruby
catalogue = Spandx::Catalogue.latest
catalogue.each do |license|
  puts license.inspect
end
```

To load an offline copy of the data.

```ruby
path = File.join(Dir.pwd, 'licenses.json')
catalogue = Spandx::Catalogue.from_file(path)
catalogue.each do |license|
  puts license.inspect
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/cibuild` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mokhan/spandx.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
