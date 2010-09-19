require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'fileutils'

describe "Db" do
  Files = Pwnbus::Configdb::Files
  Configdb = Pwnbus::Configdb
  
  shared_examples_for "paths" do
    it "should have a global path pointing to /etc" do
      Files.db_dir_paths.last[0, 5].should == '/etc/'
    end    
  end

  describe "for non-root user" do
    it_should_behave_like "paths"

    before do
      Files.should_receive(:superuser?).and_return(false)
    end
    
    it "should use a local and a global path" do
      Files.db_dir_paths.should have(2).items
    end
  end
  
  describe "for root user" do
    before do
      Files.should_receive(:superuser?).and_return(true)
    end
    
    it "should only use the global path" do
      Files.db_dir_paths.should have(1).item
    end    
  end
end

describe "Db with stubbed dir" do  
  before do
    @tempdir = "/tmp/pwnbus-#{(Time.now.to_f * 1000).to_i}"
    
    @global_dir = File.join @tempdir, 'etc/pwnbus'
    @user_dir = File.join @tempdir, 'home', 'user', '.pwnbus'
    Dir.mkdir(@tempdir)
    Files.stub!(:db_dir_global_path).and_return(@global_dir)
    Files.stub!(:db_dir_user_path).and_return(@user_dir)
  end
  
  after do
    FileUtils.rm_r(@tempdir)
  end
  
  describe "for non-root user" do
    before do
      Files.should_receive(:superuser?).at_least(:once).and_return(false)
    end

    it "saves new databases in the local dir" do
      Configdb.open('pathtest') { }
      File.exist?(@global_dir + '/pathtest.yml').should be_false
      File.exist?(@user_dir + '/pathtest.yml').should be_true
    end
  end
  
  describe "for root user" do
    before do
      Files.should_receive(:superuser?).at_least(:once).and_return(true)
    end
    
    it "saves databases in /etc'" do
      Configdb.open('pathtest') { }
      File.exist?(@user_dir + '/pathtest.yml').should be_false
      File.exist?(@global_dir + '/pathtest.yml').should be_true
    end
  end
  
  describe "with saved db" do
    before do
      Configdb.open('persistence') do |c|
        c.really.long.flag = true
        c.really.long.number = 41
        c.really.long.string = 'something'
      end
    end
    
    it "should report variables correctly" do
      Configdb.open('persistence') do |c|
        c.really.long.flag.should == true
        c.really.long.number.should == 41
        c.really.long.string.should == 'something'
      end
    end
    
    it "should make the dbfile world-readable" do
      (File.stat(@user_dir + '/persistence.yml').mode & 0777).should == 0644
    end
    
    describe "after overwriting some vars" do
      before do
        Configdb.open('persistence') do |c|
          c.really.long.number = 42
          c.really.long.flag = false
        end
      end
      
      it "should report changes correctly" do
        Configdb.open('persistence') do |c|
          c.really.long.flag.should == false
          c.really.long.number.should == 42
          c.really.long.string.should == 'something'        
        end
      end
    end
  end
  
  describe "with private db" do
    before do
      Configdb.open('.private') do |c|
        c.secret.pin = '1234'
      end
    end
    
    it "should not make the dbfile world-readable" do
      (File.stat(@user_dir + '/.private.yml').mode & 0777).should == 0600
    end
    
    it "should be able to read back data" do
      Configdb.open('.private') { |c| c.secret.pin.should == '1234' }
    end
  end
  
  describe "after crash" do
    before do
      @crash_path = @user_dir + '/crash.yml'
      @crash_new_path = @crash_path + '.new'
      FileUtils.mkdir_p @user_dir
      File.open(@crash_path, 'w') { |f| YAML.dump({'old' => 'yes'}, f) }
      File.open(@crash_new_path, 'w') { |f| YAML.dump({'old' => 'no'}, f) }
    end
    
    describe "during writing" do
      before do
        @db_old = Configdb.open('crash') { |crash| crash.old }
      end
      
      it "should read the old copy" do
        @db_old.should == 'yes'
      end
    end
    
    describe "during rename" do
      before do
        File.unlink @crash_path
        @db_old = Configdb.open('crash') { |crash| crash.old }        
      end
      
      it "should read the new copy" do
        @db_old.should == 'no'
      end
      
      it "should finish the rename" do
        File.exist?(@crash_path).should be_true
        File.exist?(@crash_new_path).should be_false
      end
    end
  end
end
