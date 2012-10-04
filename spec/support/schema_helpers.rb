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
  config.include SchemaHelpers
end
