class <%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table :settings, :force => true do |t|
      t.string :var, :null => false
      t.text   :value, :null => true
      t.string :settingable_type, :limit => 100, :null => true
      t.integer :settingable_id
      t.integer :version, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :settings
  end
end
