require 'fileutils'

# :nodoc: namespace
module Pwnbus
  
# :nodoc: file-related functionality
module Configdb
  
# Handling procedures for database files.
module Files
  # Opens the file for a configuration database. The file must exist.
  #
  # Returns a File instance.
  def self.open_db(db_path, options)
    db_path = crash_recovery_db_path db_path, options
    f = File.open db_path, 'r'
    f.flock options[:read] ? File::LOCK_SH : File::LOCK_EX
    f
  end
  
  # Peforms crash recovery on a database.
  #
  # Args:
  #   db_path:: path to a file containing a configuration database
  #   options:: same as for Configdb#new
  #
  # Returns the path to the recovered database. Most of the time, this will be 
  def self.crash_recovery_db_path(db_path, options)
    new_db_path = db_path + '.new'
    if !File.exist?(db_path)
      # Crashed during rename.
      if options[:read]        
        # Writing to the .new copy completed. The copy will be locked.
        return new_db_path
      else
        # Do the rename.
        File.rename new_db_path, db_path
        return db_path
      end
    end
          
    if File.exist?(new_db_path) && !options[:read]
      # Crashed during new version write. The new version is probably corrupted.
      File.unlink new_db_path
    end
    db_path
  end
  
  # Writes a new database version atomically.
  #
  # Args:
  #   db_path:: path to a file containing a configuration database
  #   options:: same as for Configdb#new
  #
  # Returns db_path.
  def self.write_db(db_path, options)
    new_db_path = db_path + '.new'
    File.open(new_db_path, 'w') do |f|
      f.flock File::LOCK_EX
      permissions = public_db_name?(name) ? 0644 : 0600
      File.chmod permissions, new_db_path      
      yield f
    end
    File.unlink db_path
    File.rename new_db_path, db_path
    db_path
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
      return db_path if File.exist?(db_path) || File.exist?(db_path + '.new')
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
      YAML.dump empty_db_data(name), f
    end
    permissions = public_db_name?(name) ? 0644 : 0600
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
  
  # Databases whose names start with . are public (global-read, author-write).
  def self.public_db_name?(name)
    name[0] != ?.
  end
  
  # Returns the the database directory. Creates it if it doesn't exist.
  def self.ensure_db_dir_exists
    dir_path = db_dir_paths.first
    unless File.exist? dir_path    
      FileUtils.mkdir_p dir_path
      File.chmod 0755, dir_path
    end
    dir_path
  end
  
  # Paths to the directory containing database files for the current user.
  def self.db_dir_paths
    if superuser?
      [db_dir_global_path]
    else
      [db_dir_user_path, db_dir_global_path]
    end
  end
  
  # Path to the directory holding per-user databases.
  def self.db_dir_user_path
    File.expand_path('~/.pwnbus')
  end
  
  # Path to the computer-global databases.
  def self.db_dir_global_path
    '/etc/pwnbus'
  end
  
  # True if running as the root user.
  def self.superuser?
    Process.euid == 0
  end
end  # namespace Pwnbus::Configdb::Files

end  # namespace Pwnbus::Configdb
  
end  # namespace Pwnbus
