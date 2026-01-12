# frozen_string_literal: true

require 'rake'
require 'dotenv/load'
require 'sinatra/activerecord/rake'
require 'rake/testtask'

# Load the app to ensure ActiveRecord is configured
require File.expand_path('app.rb', __dir__)

# Explicitly set database configurations for ActiveRecord tasks in Sinatra
ActiveRecord::Base.configurations = YAML.safe_load(ERB.new(File.read('config/database.yml')).result, aliases: true)

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = false
end

namespace :db do
  desc 'Create the database (if not exists) using DATABASE_URL'
  task :create do
    require 'active_record'
    url = ENV['DATABASE_URL']
    abort 'DATABASE_URL is not set' unless url && !url.empty?
    ActiveRecord::Base.establish_connection(url)
    # For PostgreSQL, create db if missing
    begin
      ActiveRecord::Base.connection
      puts 'Database connection OK'
    rescue ActiveRecord::NoDatabaseError
      require 'uri'
      uri = URI(url.sub('postgres://', 'postgresql://'))
      db_name = uri.path.delete_prefix('/')
      admin_url = url.sub(%r{/(.+)$}, '/postgres')
      ActiveRecord::Base.establish_connection(admin_url)
      ActiveRecord::Base.connection.create_database(db_name)
      puts "Created database: #{db_name}"
    end
  end
end

namespace :widgets do
  def migration_context_for(paths)
    require 'active_record'
    require 'active_record/migration'
    ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
    schema_migration = if ActiveRecord.version >= Gem::Version.new('7.2.0')
                         ActiveRecord::SchemaMigration.new(ActiveRecord::Base.connection_pool)
                       else
                         ActiveRecord::Base.connection.schema_migration
                       end
    ActiveRecord::MigrationContext.new(Array(paths), schema_migration)
  end

  desc 'Migrate a single widget: rake widgets:migrate[widget_name]'
  task :migrate, [:name] do |_t, args|
    name = args[:name]
    abort 'Provide widget name: rake widgets:migrate[widget_name]' unless name
    path = File.join(__dir__, 'lib', 'widgets', name, 'migrations')
    abort "No migrations path: #{path}" unless Dir.exist?(path)
    ctx = migration_context_for(path)
    if ctx.respond_to?(:migrate)
      ctx.migrate
    else
      ActiveRecord::Migrator.up(path)
    end
    puts "Widget migrated: #{name}"
  end

  desc 'Migrate all widgets (runs each migrations folder)'
  task :migrate_all do
    base = File.join(__dir__, 'lib', 'widgets')
    Dir.glob(File.join(base, '*', 'migrations')).each do |path|
      next unless Dir.exist?(path)

      ctx = migration_context_for(path)
      if ctx.respond_to?(:migrate)
        ctx.migrate
      else
        ActiveRecord::Migrator.up(path)
      end
      puts "Migrated: #{File.dirname(path)}"
    end
  end
end

desc 'Default task'
task :default do
  puts 'Available tasks: db:create, db:migrate, db:rollback, widgets:migrate[NAME], widgets:migrate_all'
end

namespace :queue do
  desc 'Start SolidQueue worker (if available)'
  task :work do
    begin
      require 'solid_queue'
    rescue LoadError
      abort 'solid_queue gem not installed. Add it to Gemfile and bundle install.'
    end
    if defined?(SolidQueue)
      puts 'Starting SolidQueue worker... (make sure database is migrated for SolidQueue)'
      # Placeholder: SolidQueue provides its own executables/config in Rails; in Sinatra, you may run a custom worker.
      # Implement your job polling/dispatching loop here or use SolidQueue CLI if available in your version.
      puts 'SolidQueue worker placeholder. Implement worker loop as needed.'
    end
  end
end
