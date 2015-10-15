require "ruco/version"
require 'active_support/inflector'
require 'tsort'

module Ruco

	class TsortableHash < Hash
		include TSort
		alias tsort_each_node each_key
		def tsort_each_child(node, &block)
			fetch(node).each(&block)
		end
	end

	class LitString
		attr_accessor :str
		def initialize(str, prodset)
			@str = str
		end

		def generate(indent=0)
			"#{("\t"*indent)}\"#{str}\""
		end
	end

	class Identifier
		attr_accessor :name, :prodset
		def initialize(name)
			@name = name
			@prodset = prodset
		end

		def generate(indent=0)

			code = "production->#{name.downcase} = #{name.downcase};"
			if @prodset[name][:count] > 1
				code = "production->#{name.downcase.pluralize}.push_back(#{name.downcase});"
			end
			"#{("\t"*indent)}#{name}<#{name.downcase}> (. #{code} .)"
		end
	end

	class Token
		attr_accessor :name
		def initialize(name, prodset)
			@name = name
		end

		def generate(indent=0)
			"#{("\t"*indent)}#{name} (. production->content = t->val; .)"
		end
	end

	class Sync
		def generate(indent=0)
			"#{("\t"*indent)}SYNC"
		end
	end

	class Variation < Identifier

		def generate(indent=0)
			code = "production = #{name.downcase};"
			"#{("\t"*indent)}#{name}<#{name.downcase}> (. #{code} .)"
		end
	end

	class Group
		def initialize(type=:normal, prodset={})
			@type = type
			@prodset = prodset
			@stuff = []
		end

		def Object.const_missing(m)
			return Identifier.new("#{m}")
		end

		def convert_thing(thing)
			if thing.is_a? String
				return LitString.new(thing, @prodset)
			end

			if thing.is_a? Identifier or thing.is_a? Variation

				thing.prodset = @prodset

				if !@prodset[thing.name]
					@prodset[thing.name] = {count: 0, type: :id}
				end
				@prodset[thing.name][:count] += 1
				@prodset[thing.name][:count] += 1 unless @type == :normal or @type == :either
			end

			if thing.is_a? Token
				if !@prodset[thing.name]
					@prodset[thing.name] = {count: 0, type: :token}
				end
				@prodset[thing.name][:count] += 1
				@prodset[thing.name][:count] += 1 unless @type == :normal or @type == :either
			end

			return thing
		end

		def sync
			@stuff << Sync.new
		end

		def one(thing)
			thing = convert_thing(thing)
			@stuff << thing
		end

		def either(*args)
			g = Group.new :either, @prodset

			g.instance_eval do
				args.each do |x|
					one x
				end
			end
			one g
		end

		def maybe(thing)
			g = Group.new :maybe, @prodset
			g.instance_eval do
				one thing
			end
			one g
		end

		def many(thing, options=nil)
			one thing
			maybemany thing, options
		end

		def maybemany(thing, options=nil)
			g = Group.new :multiple, @prodset
			g.instance_eval do
				if options[:separator].is_a? String
					one options[:separator]
				else
					puts "Separator needs to be a simple string"
				end if options 
				one thing
			end
			one g
		end

		def group(&block)
			g = Group.new :normal, @prodset
			g.instance_eval(&block)
			g
		end

		def generate(indent=0)

			result = []

			@stuff.each do |x|
				result << "#{x.generate(indent+1)}"
			end

			openbrace = "("
			closebrace = ")"
			divider = ""

			openbrace = "[" if @type == :maybe
			closebrace = "]" if @type == :maybe

			openbrace = "{" if @type == :multiple
			closebrace = "}" if @type == :multiple


			divider = "|" if @type == :either

			("\t"*indent) + openbrace + "\n" + result.join("#{divider}\n") + "\n" + ("\t"*indent) + closebrace
		end

	end

	class Production < Group

		attr_accessor :prodset, :prodtype

		def initialize(name, prodtype=:normal)

			@prodtype = prodtype
			@name = name
			super()
		end

	end

	class Ruco < Production
		def initialize(grammar_name, &block)
			@name = grammar_name
			super(grammar_name)
			@productions = {grammar_name => self}
			instance_eval(&block)
		end

		def grammar(name, &block)
			p = Production.new(name, &block)
			p.instance_eval(&block)
			@productions[name] = p
		end

		def variation(name, *args)
			p = Production.new(name, :variation)
			p.instance_eval do
				g = Group.new :either, @prodset
				g.instance_eval do
					args.each do |x|
						if x.is_a? Identifier
							one Variation.new(x.name)
						else
							puts "Variation needs to be a grammar"
						end
					end
				end
				one g 
			end
			@productions[name] = p
		end

		def token(name, type)
			p = Production.new(name)
			case type
			when :pascal_case
				p.instance_eval do
					one Token.new("pascalcase", @prodset)
				end
			when :camel_case
				p.instance_eval do
					one Token.new("camelcase", @prodset)
				end
			when :hex_integer
				p.instance_eval do
					one Token.new("hexinteger", @prodset)
				end
			when :integer
				p.instance_eval do
					one Token.new("integer", @prodset)
				end
			end
			@productions[name] = p
		end

		def generate_header()

			classlist = []

			parent_map = {}

			dependency_hash = TsortableHash.new

			@productions.each do |prodname, prod|

				if prod.prodtype == :normal

					prod.prodset.each do |key, prodinfo|

						if prodinfo[:type] == :id
							if !dependency_hash[prodname]
								dependency_hash[prodname] = []
							end
							dependency_hash[prodname] << "#{key}"
						end
					end

				elsif prod.prodtype == :variation

					prod.prodset.each do |key, prodinfo|

						if prodinfo[:type] == :id
							if !dependency_hash[key]
								dependency_hash[key] = []
							end
							dependency_hash[key] << "#{prodname}"

							if !parent_map[key]
								parent_map[key] = []
							end
							parent_map[key] << "#{prodname}"

						end

					end

				end

			end

			# remaining productions
			@productions.each do |prodname, prod|
				if !dependency_hash[prodname]
					dependency_hash[prodname] = []
				end
			end

			#puts "Dependency Chain:"
			#p dependency_hash

			dependency_hash.tsort.each do |prodname|

				prod = @productions[prodname]


				memberlist = []
				if prod.prodtype == :normal

					prod.prodset.each do |key, prodinfo|
						name = "#{key}"

						if prodinfo[:type] == :id

							#puts "#{name} -> #{prodinfo[:count]}"

							if prodinfo[:count] > 1
								memberlist << "#{name}Array #{name.downcase.pluralize};"
							else
								memberlist << "#{name}Ptr #{name.downcase};"
							end

						elsif prodinfo[:type] == :token

							memberlist << "std::wstring content;"
						end

					end

				elsif prod.prodtype == :variation

					enumeration_list = []
					prod.prodset.each do |key, prodinfo|
						enumeration_list << "\t#{key.upcase}_#{prodname.upcase}"
					end

					enumerations = enumeration_list.join ",\n"


					classlist << <<-TYPE_ENUM_CONTENT
enum #{prodname}Type
{
#{enumerations}
};
					TYPE_ENUM_CONTENT

					memberlist << "virtual #{prodname}Type get_#{prodname.downcase}_type() const = 0;"

				else
					puts "UNKNOWN PRODUCTION TYPE: #{prod.prodtype}"
				end

				parent_declaration = ""
				parent_impl = ""

				if parent_map[prodname]
					list = parent_map[prodname].map{|x| "public #{x}"}.join ", "
					parent_declaration = ": #{list}"

					parent_map[prodname].each do |parent|
						memberlist << <<-PARENTDECL
virtual #{parent}Type get_#{parent.downcase}_type() const
	{
		return #{prodname.upcase}_#{parent.upcase};
	}
PARENTDECL
					end

				end

				members = memberlist.map {|x| "\t#{x}"}.join "\n"

				classlist << <<-CLASSCONTENT
class #{prodname} #{parent_declaration}
{
public:
#{members}
};
typedef std::shared_ptr<#{prodname}> #{prodname}Ptr;
typedef std::vector<#{prodname}Ptr> #{prodname}Array;
			CLASSCONTENT
		end

		classes = classlist.join "\n"

		header = <<-HEADEREND

#ifndef #{@name.upcase}_HPP
#define #{@name.upcase}_HPP

/*
	WARNING: This file is generated using ruco. Please modify the .ruco file if you wish to change anything
	https://github.com/davidsiaw/ruco
*/

#include <string>
#include <memory>
#include <vector>

namespace #{@name}
{

#{classes}

}

#endif // #{@name.upcase}_HPP

			HEADEREND

			header

		end

		def generate_libhpp()
			<<-HPPCONTENT

#ifndef PARSE_#{@name.upcase}_HPP
#define PARSE_#{@name.upcase}_HPP

/*
	WARNING: This file is generated using ruco. Please modify the .ruco file if you wish to change anything
	https://github.com/davidsiaw/ruco
*/

#include <iostream>
#include <memory>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <set>

#include "Scanner.h"
#include "Parser.h"

#include "picojson.hpp"

namespace #{@name}
{
	/**
	 * Parses a source file into the data structure of #{@name}
	 */
	#{@name}Ptr Parse(std::string sourceFile);

	/**
	 * Transforms the data structure of #{@name} to an abstract syntax tree in JSON format
	 */
	picojson::value Jsonify(#{@name}Ptr parseResult);
}

#endif // PARSE_#{@name.upcase}_HPP

			HPPCONTENT
		end

		def write_jsonify_function(prodname, prod)

			pset = <<-PSETEND
		object[L"_type"] = picojson::value(L"#{prodname}");
			PSETEND

			if prod.prodtype == :variation

				switchladder = ""
				
				prod.prodset.each do |key, prodinfo|

					switchladder += <<-LADDEREND
			case #{key.upcase}_#{prodname.upcase}:
			{
				content = Compile#{key}(std::dynamic_pointer_cast<#{key}>(pointer));
				break;
			}
					LADDEREND

				end

				pset += <<-PSETEND
		picojson::object content;
		switch(pointer->get_#{prodname.downcase}_type())
		{
#{switchladder}
		}

		object[L"_content"] = picojson::value(content);
				PSETEND


			elsif prod.prodtype == :normal

				members_code = ""

				prod.prodset.each do |key, prodinfo|

					members_code += <<-MEMBERCODEEND
		// #{prodinfo}
				MEMBERCODEEND

					if prodinfo[:count] == 1

						if prodinfo[:type] == :token

							members_code += <<-PSETEND
		object[L"_token"] = picojson::value(pointer->content);
							PSETEND

						elsif prodinfo[:type] == :id
							members_code += <<-PSETEND

		picojson::object #{key.downcase};

		#{key.downcase} = Compile#{key}(pointer->#{key.downcase});

		object[L"#{key.downcase}"] = picojson::value(#{key.downcase});
							PSETEND
						end

					else

						if prodinfo[:type] == :token
							raise "Unimplemented"

						elsif prodinfo[:type] == :id
							members_code += <<-PSETEND

		picojson::array #{key.downcase}s;

		for(unsigned i=0; i<pointer->#{key.downcase}s.size(); i++)
		{
			#{key.downcase}s.push_back(picojson::value(Compile#{key}(pointer->#{key.downcase}s[i])));
		}

		object[L"#{key.downcase}s"] = picojson::value(#{key.downcase}s);
							PSETEND
						end

					end

				end

				pset += <<-PSETEND
		

#{members_code}


				PSETEND

			end

			funcname = "picojson::object Compile#{prodname}(#{prodname}Ptr pointer)"

			funcdef = <<-FUNCTIONEND
	#{funcname}
	{
		picojson::object object;

		// #{prod.prodtype}
#{pset}
		return object;
	}

			FUNCTIONEND

			{name: funcname, definition: funcdef}

		end

		def generate_libcpp()

			functions = ""
			function_declarations = ""

			@productions.each do |prodname, prod|

				f = write_jsonify_function(prodname, prod)
				functions += f[:definition]
				function_declarations += <<-FUNCDECLEND
	#{f[:name]};
				FUNCDECLEND
			end

			<<-CPPCONTENT

#include "parse_#{@name.downcase}.hpp"

/*
	WARNING: This file is generated using ruco. Please modify the .ruco file if you wish to change anything
	https://github.com/davidsiaw/ruco
*/

namespace #{@name}
{
	#{@name}Ptr Parse(std::string sourceFile)
	{
		std::shared_ptr<FILE> fp (fopen(sourceFile.c_str(), "r"), fclose);
		std::shared_ptr<Scanner> scanner (new Scanner(fp.get()));
		std::shared_ptr<Parser> parser (new Parser(scanner.get()));
		parser->Parse();

		return parser->#{@name.downcase};
	}

#{function_declarations}
#{functions}

	picojson::value Jsonify(SerialistPtr parseResult)
	{
		return picojson::value(CompileSerialist(parseResult));
	}

}

			CPPCONTENT
		end

		def generate_makefile
			<<-MAKEFILEEND
V = 0
AT_0 := @
AT_1 :=
REDIR_0 := > /dev/null
REDIR_1 :=
AT = $(AT_$(V))
REDIR = $(REDIR_$(V))

CXXFLAGS=-g -Wall -std=gnu++11
	
LDFLAGS=
TARGET=#{@name.downcase}_parse
SRCDIR=.
SRC=$(shell find $(SRCDIR) -name "*.cpp") 
OUT=obj
OBJS=$(SRC:%.cpp=$(OUT)/%.o)
DEPS=$(SRC:%.cpp=$(OUT)/%.d)
NODEPS=clean

.PHONY = all clean

.SECONDEXPANSION:

all: $(TARGET)
	$(AT)echo "Build complete"

clean:
	$(AT)-rm -rf $(TARGET) $(OUT)

ifeq (0, $(words $(findstring $(MAKECMDGOALS), $(NODEPS))))
    -include $(DEPS)
endif

$(TARGET): $(OBJS) $(LUA)
	$(AT)echo [LINK] $@
	$(AT)$(CXX) $(CXXFLAGS) $^ $(LDFLAGS) -o $@ 

%/.f:
	$(AT)echo [MKDIR] $(dir $@)
	$(AT)mkdir -p $(dir $@) 
	$(AT)touch $@

$(OUT)/%.d:%.cpp $$(@D)/.f 
	$(AT)echo [DEP] $<
	$(AT)$(CXX) $(CXXFLAGS) -MM -MT '$(patsubst %.d,%.o,$@)' $< -MF $@

$(OUT)/%.o:%.cpp $(OUT)/%.d
	$(AT)echo [C++] $<
	$(AT)$(CXX) $< $(CXXFLAGS) -c -o $@

.PRECIOUS: %/.f

			MAKEFILEEND
		end

		def generate_atg()

			productionlist = []
			productiondecl = []


			@productions.each do |prodname, prod|

				decllist = []

				prod.prodset.each do |key, prodinfo|
					if prodinfo[:type] == :id
						decllist << "(. #{key}Ptr #{key.downcase}; .)"
					end
				end

				declarations = decllist.join "\n"

				attributes = "<#{prodname}Ptr& production>" unless prodname == @name

				constructor = ""

				constructor = "(. production = std::make_shared<class #{prodname}>(); .)" if prod.prodtype == :normal

				production_string = <<-PRODUCTION
#{prodname}#{attributes} = #{constructor}
#{declarations}
#{prod.generate}
.
				PRODUCTION

				production_string.gsub!(/production/, @name.downcase) if prodname == @name

				productionlist << production_string
			end

			productions = productionlist.join("\n")

			<<-FRAMEEND

#include <iostream>
#include <memory>
#include "#{@name}.hpp"

/*
	WARNING: This file is generated using ruco. Please modify the .ruco file if you wish to change anything
	https://github.com/davidsiaw/ruco
*/

COMPILER #{@name}

#{@name}Ptr #{@name.downcase};

CHARACTERS
	bigletter    = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".
	letter       = "abcdefghijklmnopqrstuvwxyz".
	underscore   = "_".
	digit        = "0123456789".
	cr           = '\\r'.
	lf           = '\\n'.
	tab          = '\\t'.
	stringCh     = ANY - '"' - '\\\\' - cr - lf.
	charCh       = ANY - '\\'' - '\\\\' - cr - lf.
	printable    =  '\\u0020' .. '\\u007e'.
	hex          = "0123456789abcdef".

TOKENS
	pascalcase   = bigletter { bigletter | letter | digit }.
	camelcase    = letter { bigletter | letter | digit }.

	integer      = digit { digit }.
	hexinteger   = '0' 'x' hex { hex }.

	string       = '"' { stringCh | '\\\\' printable } '"'.
	badString    = '"' { stringCh | '\\\\' printable } (cr | lf).
	char         = '\\'' ( charCh | '\\\\' printable { hex } ) '\\''.
	endOfLine    = cr | lf.

PRAGMAS
	ddtSym    = '$' { digit | letter }. 
	optionSym = '$' letter { letter } '='
	            { digit | letter
	            | '-' | '.' | ':'
	            }.


COMMENTS FROM "/*" TO "*/" NESTED
COMMENTS FROM "//" TO lf

IGNORE tab + cr + lf

/*-------------------------------------------------------------------------*/

PRODUCTIONS

#{productions}


END #{@name}.

FRAMEEND

		end
	end
end

