# Configure Rails Envinronment
ENV['RAILS_ENV'] = 'test'
require File.expand_path('../dummy/config/environment.rb',  __FILE__)

require 'rspec/rails'
require 'rspec/autorun'
#require 'bourne'

ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__), '../')

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(ENGINE_RAILS_ROOT, 'spec/support/**/*.rb')].each { |f| require f }


module SchemaHelpers
  #will generate for all the schemas run within this spec
  #remove full line comment (disclaimer at top)
  def schema
    yield ActiveRecord::Base.connection

    stream = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.string.gsub(/^#.*\n/,'')
  end

  def schema_for(table_name)
    schema do |connection|
      connection.create_table table_name do |t|
        yield t
      end
    end
  end
end

RSpec.configure do |config|
#  config.mock_with :mocha
  config.use_transactional_fixtures = true
  config.backtrace_clean_patterns = [
    #/\/lib\d*\/ruby\//,
    #/bin\//,
    #/gems/,
    #/spec\/spec_helper\.rb/,
    /lib\/rspec\/(core|expectations|matchers|mocks)/
  ]

  config.include SchemaHelpers
end
