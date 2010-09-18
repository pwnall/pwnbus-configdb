require 'fileutils'

# :nodoc: namespace
module Pwnbus
  
# :nodoc: file-related functionality
module Configdb
  
module Files
  # Opens the file for a configuration database. The file must exist.
  def self.open_db(db_path, options)
    f = File.open db_path, (options[:read] ? 'r' : 'r+')
    f.flock options[:read] ? File::LOCK_SH : File::LOCK_EX
    f
  end
  

  # True if the file is accessible with the desired Configdb#open options.
  #
  # Args:
  #   db_path:: path to a database file
  #   options:: same as for Configdb#new
  def self.can_access_path?(db_path, options)
    db_stat = File.stat(db_path)
    options[:read] ? db_stat.readable? : db_stat.writable?
  end
  
  # The path to a database, or nil if the database doesn't exist.
  # 
  # Args:
  #   name:: the database name
  def self.find_db(name)
    db_dir_paths.each do |dir_path|
      db_path = File.join dir_path, name + '.yml'
      return db_path if File.exist?(db_path) || File.exist(db_path + '.bk')
    end
    nil
  end
  
  # Creates a new database. The database must not exist.
  #
  # Args:
  #   name:: the database name
  #   options:: same as for Configdb#open
  #
  # Returns the path to the database file.
  def self.create_db(name, options)
    db_path = File.join ensure_db_dir_exists, name + '.yml'
    File.open(db_path, 'w') do |f|
      f.flock File::LOCK_EX
      YAML.dump(empty_db_data, f)
    end
    permissions = options[:public] ? 0644 : 0600
    File.chmod permissions, db_path
    db_path
  end
  
  # The contents of a empty (newly created) database.
  #
  # Args:
  #    name:: the database's name
  def self.empty_db_data(name)
    {}
  end
  
  # Returns the the database directory. Creates it if it doesn't exist.
  def self.ensure_db_dir_exists
    dir_path = db_dir_paths.first
    return if File.exist? dir_path
    
    FileUtils.mkdir_p dir_path
    FileUtils.chmod 0755, dir_path
  end
  
  # Paths to the directory containing database files for the current user.
  def self.db_dir_paths
    if superuser?
      ['/etc/pwnbus']
    else
      [File.expand_path('~/.pwnbus'), '/etc/pwnbus']
    end
  end
  
  # True if running as the root user.
  def self.superuser?
    Process.euid == 0
  end
  
end  # namespace Pwnbus::Configdb::Files

end  # namespace Pwnbus::Configdb
  
end  # namespace Pwnbus
