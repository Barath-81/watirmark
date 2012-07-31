require 'spec_helper'
require 'watirmark'

describe "models name" do
  before :all do
    @model = Watirmark::Model::Base.new(:middle_name) do
      default.middle_name  {"#{model_name} middle_name".strip}
      compose :full_name do
        "#{model_name}foo"
      end
    end
  end


  specify "can set the models name" do
    m = @model.new
    m.model_name = 'my_model'
    m.model_name.should == 'my_model'
  end


  specify "setting the models name changes the uuid" do
    m = @model.new
    m.model_name = 'my_model'
    m.uuid.should =~ /^my_model/
  end


  specify "setting the models name changes the defaults" do
    m = @model.new
    m.model_name = 'my_model'
    m.middle_name.should =~ /^my_model/
  end


  specify "setting the models name changes the composed fields" do
    m = @model.new
    m.model_name = 'my_model'
    m.full_name.should =~ /^my_model/
  end
end


describe "default values" do
  before :all do
    @model = Watirmark::Model::Base.new(:first_name, :last_name, :middle_name, :nickname, :id) do
      default.first_name  'my_first_name'
      default.last_name   'my_last_name'
      default.middle_name  {"#{model_name} middle_name".strip}
      default.id  "#{uuid}"
    end
  end


  specify "retrieve a default setting" do
    @model.new.first_name.should == 'my_first_name'
  end


  specify "retrieve a default proc setting" do
    m = @model.new
    m.middle_name.should == 'middle_name'
    m.model_name = 'foo'
    m.middle_name.should == 'foo middle_name'
  end

  specify "should set a uuid" do
    m = @model.new
    m.id.should_not be_nil
  end

  specify "update a default setting" do
    m = @model.new
    m.first_name = 'fred'
    m.first_name.should == 'fred'
  end
end

describe "composed fields" do
  before :all do
    @model = Watirmark::Model::Base.new(:first_name, :last_name, :middle_name, :nickname) do
      default.first_name  'my_first_name'
      default.last_name   'my_last_name'
      default.middle_name  {"#{model_name}middle_name".strip}

      compose :full_name do
        "#{first_name} #{last_name}"
      end

    end
  end

  specify "set a value that gets used in the composed string" do
    m = @model.new
    m.full_name.should == "my_first_name my_last_name"
    m.first_name = 'coolio'
    m.full_name.should == "coolio my_last_name"
  end

  specify "get a string composed in the default declaration" do
    m = @model.new
    m.model_name = 'foo_'
    m.middle_name.should == "foo_middle_name"
  end
end


describe "Inherited Models" do
  specify "should inherit defaults" do
    User = Watirmark::Model::Person.new(:username, :password, :street1)
    @login = User.new
    @login.username.should =~ /user_/
    @login.password.should == 'password'
    @login.street1.should == '3405 Mulberry Creek Dr'
  end

  specify "should inherit unnamed methods" do
    User = Watirmark::Model::Person.new(:username, :password, :firstname)
    @login = User.new
    @login.firstname.should =~ /first_/
  end

end

describe "instance values" do
  before :all do
    Login = Watirmark::Model::Base.new(:username, :password)
  end


  specify "set a value on instantiation" do
    @login = Login.new(:username => 'username', :password => 'password' )
    @login.username.should == 'username'
    @login.password.should == 'password'
  end

end


describe "models containing models" do
  before :all do
    Login = Watirmark::Model::Base.new(:username, :password) do
      default.username  'username'
      default.password  'password'
    end

    User = Watirmark::Model::Base.new(:first_name, :last_name) do
      default.first_name  'my_first_name'
      default.last_name   'my_last_name'

      add_model Login.new
    end

    Donor = Watirmark::Model::Base.new(:credit_card) do
      add_model User.new
    end
  end


  specify "should be able to see the models" do
    @model = User.new
    @model.login.should be_kind_of Struct
    @model.login.username.should == 'username'
  end

  specify "should be able to see the models multiple steps down" do
    @model = Donor.new
    @model.user.login.should be_kind_of Struct
    @model.user.login.username.should == 'username'
  end

end


describe "models containing collections of models" do
  before :all do
    SDP = Watirmark::Model::Base.new(:name, :value)

    Config = Watirmark::Model::Base.new(:name) do
      add_model SDP.new(:name=>'a', :value=>1)
      add_model SDP.new(:name=>'b', :value=>2)
    end
    @model = Config.new
  end


  specify "call to singular method will return the first model added" do
    @model.sdp.should be_kind_of Struct
    @model.sdp.name.should == 'a'
  end

  specify "call to collection should be an enumerable" do
    @model.sdps.size.should == 2
    @model.sdps.first.name.should == 'a'
    @model.sdps.last.name.should == 'b'
  end

  specify "should be able to add models on the fly" do
    @model.add_model SDP.new(:name=>'c', :value=>3)
    @model.add_model SDP.new(:name=>'d', :value=>4)
    @model.sdps.size.should == 4
    @model.sdps.first.name.should == 'a'
    @model.sdps.last.name.should == 'd'
  end

end

describe "search a model's collection for a given model'" do

  before :all do
    Foo =  Watirmark::Model::Base.new(:first_name)
    User = Watirmark::Model::Base.new(:first_name)
    Login = Watirmark::Model::Person.new(:username)
    Password = Watirmark::Model::Base.new(:password)
    @password = Password.new
    @login = Login.new
    @login.add_model @password
    @user = User.new
    @user.add_model @login
  end

  it 'should be able to see itself' do
    @user.find(User).should == @user
  end

  it 'should be able to see a sub_model' do
    @user.find(Login).should == @login
  end

  it 'should be able to see a nested sub_model' do
    @user.find(Password).should == @password
  end

  it 'should be able to see a sub_model' do
    lambda{@user.find(Foo)}.should raise_error(Watirmark::ModelNotFound)
  end
end

