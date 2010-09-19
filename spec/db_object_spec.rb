require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Db object" do
  before do
    File.open File.expand_path('../fixtures/db.yml', __FILE__) do |f|
      @db = Pwnbus::Configdb::Db.new f
    end
    @proxy = @db.proxy
  end
   
  it "reads simple key" do
    @proxy.variable.should == 'value'
  end
  
  it "reads nested key" do
    @proxy.deeper.variable.should == 'deeper value'
  end
  
  it "changes simple key" do
    @proxy.variable = 'new value'
    @proxy.variable.should == 'new value'
  end
  
  it "changes nested key" do
    @proxy.deeper.variable = 'new deeper value'
    @proxy.deeper.variable.should == 'new deeper value'
  end
  
  it "returns nil? object for non-existing keys" do
    @proxy.none.should be_nil
  end

  it "returns nil? object for non-existing nested keys" do
    @proxy.none.none.should be_nil
  end
  
  it "inserts simple key" do
    @proxy.new_key.should be_nil
    @proxy.new_key = 'new value'
    @proxy.new_key.should == 'new value'
  end
  
  it "inserts nested key" do
    @proxy.newer.new_key.should be_nil
    @proxy.newer.new_key = 'new deep value'
    @proxy.newer.new_key.should == 'new deep value'    
  end
  
  it "inserts nested key off existing prefix" do
    @proxy.deeper.new_key.should be_nil
    @proxy.deeper.new_key = 'new mixed value'
    @proxy.deeper.new_key.should == 'new mixed value'
  end
  
  it "is not dirty at start" do
    @db.should_not be_dirty
  end
  
  it "is not dirty after read" do
    @proxy.variable
    @db.should_not be_dirty
  end
  
  it "is dirty after write" do
    @proxy.variable = 'value'
    @db.should be_dirty
  end
end
