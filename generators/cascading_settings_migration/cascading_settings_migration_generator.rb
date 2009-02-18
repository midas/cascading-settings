class CascadingSettingsMigrationGenerator < Rails::Generator::NamedBase
  def initialize(runtime_args, runtime_options = {})
    runtime_args << 'add_settings_table' if runtime_args.empty?
    super
  end

  def manifest
    record do |m|
      m.migration_template 'cascading_settings_migration.rb', 'db/migrate'
    end
  end
end
