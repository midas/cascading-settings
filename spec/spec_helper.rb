#$: << File.join(File.dirname(__FILE__), '..', 'lib')
require 'rubygems'
require 'activerecord'
require '../lib/cascading_settings.rb'
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")
ActiveRecord::Schema.define(:version => 1) do
  create_table :accounts, :force => true do |t|
    t.string  :name
  end
  create_table :users, :force => true do |t|
    t.integer :account_id
    t.string  :name
  end
  create_table :settings, :force => true do |t|
    t.string :var, :null => false
    t.text   :value, :null => true
    t.string :settingable_type, :limit => 100, :null => true
    t.string :friendly_name, :description
    t.integer :settingable_id, :null => true
    t.timestamps
  end  
end

class Setting < CascadingSettings::Setting
  validates_presence_of :value, :var
  
  attr_human_name :friendly_name => 'Setting', :translated_value => 'Value'

  def translated_value
    return YAML.load( self.value ) unless self.value.nil?
    ''
  end

  def translated_value=( val )
    self.value = val
  end

  protected
end

class Account < ActiveRecord::Base
  has_many :users
  settingable
end

class User < ActiveRecord::Base
  belongs_to :account
  settingable
end