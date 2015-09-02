# Ruco

Ruco generates the boilerplate code for Coco/R. It has a very simple DSL that generates C++ code and the ATG file.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruco'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruco

## Usage

A very simple ruco file looks like this:

```ruby
# mygrammar.ruco

token "Type", :pascal_case 		# There is a token named Type and has PascalCase
token "Name", :camel_case		# There is a token named Name and has camelCase

grammar "Statement" do 			# This is equivalent to a production in Coco/R
	one Type
	one Name
end

grammar "Format" do 

	one group {					# Group things together using the group method
		one "format" 
		one "{"
		many Statement 			# One or more Statements
		one "}"
	}
end

maybemany Format 				# Zero or more Formats
```

Generate the code by doing:

```
$ ruco mygrammar.ruco MyGrammar
```

This will produce MyGrammar.atg and MyGrammar.hpp with the required AST data structures.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davidsiaw/ruco. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

