module CascadingSettings
  class Setting < ActiveRecord::Base

    cattr_accessor :defaults
    @@defaults = {}.with_indifferent_access

    #get or set a variable with the variable as the called method
    def self.method_missing(method, *args)
      method_name = method.to_s
      super(method, *args)

    rescue NoMethodError
      if method_name =~ /=$/
        var_name = method_name.gsub('=', '')
        value = args.first
        self[var_name] = value
      else
        self[method_name]
      end
    end

    named_scope :for_system, :conditions => { :settingable_type => nil }
    named_scope :for_account, lambda { |*args|
        conditions = { :settingable_type => 'Account' }
        unless args.size == 0
          if args.first.is_a?( ActiveRecord::Base )
            conditions.merge!( :settingable_id => args.first.id  )
          else
            conditions.merge!( :settingable_id => args.first  )
          end
        end
        { :conditions => conditions }
    }
    named_scope :for_user, lambda { |*args|
        conditions = { :settingable_type => 'User' }
        unless args.size == 0
          if args.first.is_a?( ActiveRecord::Base )
            conditions.merge!( :settingable_id => args.first.id  )
          else
            conditions.merge!( :settingable_id => args.first  )
          end
        end
        { :conditions => conditions }
    }

    def self.resolve_all( settingable=nil )
      system_level = self.for_system
      unless settingable.nil?
        if settingable.is_a?( Account )
          account_level = self.for_account( settingable )
        elsif settingable.is_a?( User )
          account_level = self.for_account( settingable.account )
          user_level = self.for_user( settingable )
        end
      end
      
      default_hash = @@defaults

      system_hash = {}
      system_level.each do |record|
        system_hash[(record.var).to_sym] = record.value
      end

      account_level = Array.new if account_level.nil?
      account_hash = {}
      account_level.each do |record|
        account_hash[(record.var).to_sym] = record.value
      end

      user_level = Array.new if user_level.nil?
      user_hash = {}
      user_level.each do |record|
        user_hash[(record.var).to_sym] = record.value
      end

      default_hash.merge(system_hash).merge( account_hash ).merge( user_hash )
    end

    def self.resolve( settingable, var_name )
      default_level = self.send(var_name)
      system_level = self.object( var_name )
      if settingable.is_a?( Account )
        account_level = self.object_scoped( settingable, var_name )
      elsif settingable.is_a?( User )
        account_level = self.object_scoped( settingable.account, var_name )
        user_level = self.object_scoped( settingable, var_name )
      end

      return user_level.value unless user_level.nil?
      return account_level.value unless account_level.nil?
      return system_level.value unless system_level.nil?
      return default_level unless default_level.nil?
      nil
    end

    #def self.all
    #  vars = find(:all, :select => 'var, value')
    #
    #  result = {}
    #  vars.each do |record|
    #    result[record.var] = record.value
    #  end
    #  result.with_indifferent_access
    #end

    #retrieve a setting value by [:var_name] or [scoping_object => :var_name] notation
    def self.[]( var_name_or_hash )
      if var_name_or_hash.is_a?( Hash )
        settingable, var_name = var_name_or_hash.shift
        var_name = var_name.to_sym
        self.resolve( settingable, var_name )
      else
        var_name = var_name_or_hash.to_sym
        if var = object( var_name )
          var.value
        elsif @@defaults[var_name]
          @@defaults[var_name]
        else
          nil
        end
      end
    end

    #set a setting value by [:var_name] or [scoping_object => :var_name] notation
    def self.[]=( var_name_or_hash, value )
      var_name = var_name.to_s
      if var_name_or_hash.is_a?( Hash )
        settingable, var_name = var_name_or_hash.shift
        record = object_scoped( settingable, var_name ) || settingable.settings.build( :var => var_name.to_s )
      else
        var_name = var_name_or_hash
        record = object(var_name) || Setting.new( :var => var_name.to_s )
      end
      record.value = value
      record.save
    end

    #retrieve the actual Setting record
    def self.object(var_name)
      find( :first, :conditions => { :var => var_name.to_s, :settingable_type => nil } )
    end

    #retrieve the actual scoped Setting record
    def self.object_scoped( settingable, var_name )
      settingable.settings.find( :first, :conditions => { :var => var_name.to_s } )
    end

    #get the value field, YAML decoded
    def value
      YAML::load(self[:value])
    end

    #set the value field, YAML encoded
    def value=(new_value)
      self[:value] = new_value.to_yaml
    end

  end
end