module CascadingSettings
  module Settingable

    def self.included( base ) #:nodoc:
      super
      base.extend( ClassMethods )
    end

    module ClassMethods

      def settingable( options={} )

        class_eval do
          has_many :settings, :as => :settingable, :dependent => :destroy
        end

      end

    end

  end
end

ActiveRecord::Base.send( :include, CascadingSettings::Settingable ) if defined?( ActiveRecord::Base )
