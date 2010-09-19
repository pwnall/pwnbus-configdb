require File.expand_path('../configdb/db.rb', __FILE__)
require File.expand_path('../configdb/files.rb', __FILE__)

# :nodoc: namespace
module Pwnbus

# Pure-ruby database for configuration variables.
module Configdb
  # Opens a configuration database. The database is created if it doesn't exist.
  #
  # Args:
  #   name:: the database name; if the name starts with a ., the database is
  #          only readable to the current user, otherwise it is public (readable
  #          to everyone, but only writable by the current user)
  #   options:: the following keys are recognized
  #     :read:: opens the database only for reading
  #
  # Yields a proxy object that can be used to access the database.  
  #
  # Returns the value produced by the block.
  #
  # Example:
  #    Pwnbus::Configdb.open('system') do |system|
  #      system.os.name = 'Ubuntu'
  #      system.os.version = '10.04.1'
  #    end
  def self.open(name, options = {})
    db_path = Files.find_db(name) || Files.create_db(name, options)
    
    db_file = Files.open_db(db_path, options)
    db = Db.new db_file
    begin
      return_value = yield db.proxy
      if db.dirty?
        Files.write_db db_path, options do |wf|
          db.write wf
        end
      end
      return_value
    ensure
      db.close
      db_file.close
    end
  end  
end  # namespace Pwnbus::Configdb

end  # namespace Pwnbus
