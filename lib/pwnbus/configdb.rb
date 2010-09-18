require File.expand_path('../configdb/file.rb', __FILE__)
require File.expand_path('../configdb/object.rb', __FILE__)

# :nodoc: namespace
module Pwnbus


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
    unless Files.can_access_path?(db_path, options)
      raise "Access denied for configdb #{name}"
    end
    
    db_file = Files.open_db(name, options)
    db = Pwnbus::Configdb
    begin
      yield f
    ensure
      db.close
      db_file.close
    end
  end  
end  # namespace Pwnbus::Configdb

end  # namespace Pwnbus
