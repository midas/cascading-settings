require 'spec_helper'
describe "Cascading Settings" do
  after(:each) do
    Setting.delete_all
    Account.delete_all
    User.delete_all
  end
  describe "Where one setting resolves properly" do
    describe "Default" do
      before do
        Setting.defaults[:test_setting] = "default"
      end
      it "should resolve to default" do
        Setting.test_setting.should eql("default")
      end
    end
    describe "System" do
      before do
        Setting.defaults[:test_setting] = "default"
      end
      it "should resolve to default setting" do
        Setting[:test_setting].should eql("default")
      end
      it "should resolve to system" do
        lambda do
          Setting.test_setting = "system"
        end.should change(Setting, :count).by(1)
        Setting[:test_setting].should eql("system")
      end
    end
    describe "Account" do
      before do
        Setting.defaults[:test_setting] = "default"
        @account = Account.create!(:name => "test account")
      end
      it "should resolve to default setting" do
        Setting[@account => :test_setting].should eql("default")
      end
      it "should resolve to system setting" do
        Setting.test_setting = "system"
        Setting[@account => :test_setting].should eql("system")
      end
      it "should resolve to account" do
        Setting[@account => :test_setting] = "account"
        Setting[@account => :test_setting].should eql("account")
      end
    end
    describe "User" do
      before do
        Setting.defaults[:test_setting] = "default"
        @account = Account.create!(:name => "test account")
        @user = @account.users.build(:name => "test user")
        @user.save
      end
      it "should resolve to default setting" do
        Setting[@user => :test_setting].should eql("default")
      end
      it "should resolve to system setting" do
        Setting.test_setting = "system"
        Setting[@user => :test_setting].should eql("system")
      end
      it "should resolve to account" do
        Setting[@account => :test_setting] = "account"
        Setting[@user => :test_setting].should eql("account")
      end
      it "should resolve to user" do
        Setting[@user => :test_setting] = "user"
        Setting[@user => :test_setting].should eql("user")
      end
    end
  end
  describe "Where multiple settings resolve properly" do
    before do
      @account = Account.create!(:name => "test account")
      @user = @account.users.build(:name => "test user")
      @user.save!
      
      Setting.defaults[:default_setting] = "default"
      Setting.system_setting = "system"
      Setting[@account => :account_setting] = "account"
      Setting[@user => :user_setting] = "user"
    end
    it "should resolve all settings in a hash" do
      Setting.resolve_all.should eql({
        "default_setting" => "default",
        "system_setting"  => "system"
        })

      Setting.resolve_all(@account).should eql({
        "default_setting" => "default",
        "system_setting"  => "system",
        "account_setting" => "account"
        })

      Setting.resolve_all(@user).should eql({
        "default_setting" => "default",
        "system_setting"  => "system",
        "account_setting" => "account",
        "user_setting"    => "user"
        })
    end
  end
  describe "Where default setting" do
    it "is returned on resolve_all" do
      Setting.defaults[:default_setting] = "default"
      Setting.resolve_all.should eql({"default_setting" => "default"})
    end
  end
end