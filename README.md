# Ruco

Ruco generates the boilerplate code for Coco/R. It has a very simple DSL that generates C++ code and the ATG file.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruco-cpp'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruco-cpp

## Usage

A very simple ruco file looks like this:

```ruby
# mygrammar.ruco

token "Type", :pascal_case 		# There is a token named Type and has PascalCase
token "Name", :camel_case		# There is a token named Name and has camelCase
token "Integer", :integer		# There is a token named Integer and is an integer

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

### Code Generation

Generate the code by doing:

```
$ ruco mygrammar.ruco MyGrammar
```

This will write the following files in the current directory:

- `MyGrammar.atg` - the grammar for coco/R
- `Parser.cpp` - parser code generated by coco/R
- `Scanner.cpp` - scanner code generated by coco/R
- `parse_MyGrammar.cpp` - code for parsing MyGrammar
- `picojson.hpp`
- `MyGrammar.hpp` - data structures for MyGrammar
- `Parser.h`
- `Scanner.h`
- `parse_MyGrammar.hpp`
- `Makefile` - creates one if it does not find one in the current directory. This is a simple Makefile that builds all files in the current directory

### Using the generated code

It is up to use the functions in `parse_MyGrammar.hpp`. There are two functions:

```
namespace MyGrammar
{
	/**
	 * Parses a source file into the data structure of MyGrammar
	 */
	MyGrammarPtr Parse(std::string sourceFile);

	/**
	 * Transforms the data structure of MyGrammar to an abstract syntax tree in JSON format
	 */
	picojson::value Jsonify(MyGrammarPtr parseResult);
}
```

Simply call `Parse()` on a source file that follows your grammar and it will return a `std::shared_ptr` containing the AST. If you wish to see or process the AST with another tool, you can export it by calling `Jsonify()` on the parse result.

### Building the code

As shown above ruco will generate a Makefile for you. However the code will not compile unless you have a `main()` function. You need to write this code yourself.

Feel free to ignore the Makefile if you wish to use the code generated as a library instead.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davidsiaw/ruco. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

