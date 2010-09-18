require File.expand_path('../configdb/db.rb', __FILE__)
require File.expand_path('../configdb/files.rb', __FILE__)

# :nodoc: namespace
module Pwnbus

# Pure-ruby database for configuration variables.
module Configdb
  # Opens a configuration database. The database is created if it doesn't exist.
  #
  # Args:
  #   name:: the database name
  #   options:: the following keys are recognized
  #     :read:: opens the database only for reading
  #     :public:: 
  def self.open(name, options = {})
    db_path = Files.find_db(name) || Files.create_db(name, options)
    
    db_file = Files.open_db(name, options)
    db = Pwnbus::Configdb
    begin
      yield f
      if db.dirty?
        Files.write_file db_path do |wf|
          db.write wf
        end
      end
    ensure
      db.close
      db_file.close
    end
  end  
end  # namespace Pwnbus::Configdb

end  # namespace Pwnbus
