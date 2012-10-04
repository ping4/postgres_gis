# -*- encoding: utf-8 -*-
require File.expand_path('../lib/postgres_gis/version', __FILE__)
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'postgres_gis/version'

Gem::Specification.new do |gem|
  gem.name          = "postgres_gis"
  gem.version       = PostgresGis::VERSION
  gem.platform = $platform || RUBY_PLATFORM[/java/] || Gem::Platform::RUBY

  gem.authors       = ["Keenan Brock"]
  gem.email         = ["keenan.brock@thebrocks.net"]
  gem.description   = %q{Adds PostgreSQL GIS support to ActiveRecord.
Works with GeoRuby adapter, jruby, mri 1.9.3 (pg database adapter) and postgres_ext}
  gem.summary       = %q{Postgres GIS (aka postgis) GeoRuby ActiveRecord Support}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'activerecord', '~> 3.2.0'
  #TODO: change to 'georuby'
  gem.add_dependency 'GeoRuby', '>= 1.3.0'
  gem.add_dependency 'postgres_ext' #, '~> 0.0.9'

  gem.add_development_dependency 'rails', '~> 3.2.0'
  gem.add_development_dependency 'rspec-rails', '~> 2.9.0'
  if gem.platform.to_s == 'java'
    gem.add_development_dependency 'activerecord-jdbcpostgresql-adapter'
  else
    gem.add_development_dependency 'pg', '~> 0.13.2'
  end
  unless ENV['CI']
    if RUBY_PLATFORM =~ /java/
      gem.add_development_dependency 'ruby-debug'
    elsif RUBY_VERSION == '1.9.3'
      gem.add_development_dependency 'debugger', '~> 1.1.2'
    end
  end
  gem.add_development_dependency 'fivemat'
end
