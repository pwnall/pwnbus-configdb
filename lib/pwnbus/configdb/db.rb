require 'yaml'

# :nodoc: namespace
module Pwnbus
  
# :nodoc: file-related functionality
module Configdb
  
# Database instance.
class Db
  attr_reader :data
  attr_reader :proxy
  
  # Database initialized with the contents of a file.
  #
  # Args:
  #   file:: File instance
  def initialize(file)
    @data = YAML.load file
    @proxy = Proxy.new self, ''
  end
  
  # Writes the database contents to a file.
  #
  # Args:
  #   file:: File instance
  #
  # Returns true.
  def write(file)
    file.truncate 0
    YAML.dump file
    true
  end
  
  # Reads a key from the database.
  #
  # Args:
  #   key:: string or symbol
  #
  # Returns the value associated with the key, or nil if the key does not exist.
  def [](key)
    @data[key.to_s]
  end
    
  # Inserts or updates a key in the database.
  #
  # Args:
  #   key:: string or symbol
  #   value:: the value to be associated with the key
  #
  # Returns value.
  def []=(key, value)
    @data[key.to_s] = value.dup
    value
  end
  
  # Reads a key from the database, creating a proxy for inexistent keys.
  #
  # Args:
  #   key:: string or symbol
  #
  # Returns the value associated with the key, or a database access proxy if the
  # key doesn't exist. This makes it possible to have .-separated keys, like
  # db.user.name = 'abc'.
  def proxy_get(key)
    (value = self[key]) ? value : Proxy.new(self, key + '.')
  end
  
  # Inserts or updates
  #
  # Args:
  #   key:: string or symbol
  #   value:: the value to be associated with the key
  #
  # Returns value.
  def proxy_set(key, value)
    self[key] = value
  end

  if defined? BasicObject
    # :nodoc: superclass for 1.9+ 
    class Proxy < BasicObject; end
  else
    # :nodoc: superclass for 1.8
    class Proxy < Object; end
  end

# Easy access to a configuration database.
class Proxy
  def initialize(database, prefix)
    @db = database
    @prefix = prefix
    @eigenclass = (class <<self; self; end)
  end
  
  # Proxy objects aren't database values, so they behave like nil.
  def nil?
    true
  end
  
  # Proxy objects aren't database values, so they behave like nil.
  def empty?
    true
  end
  
  # Pretty access
  def method_missing(name, *args)
    db_key = @prefix + name.to_s
    do_write = false
    
    case db_key[-1]
    when ??
      db_key = db_key[0...-1]
    when ?=
      db_key = db_key[0...-1]
      do_write = true
    end
    
    if do_write
      @eigenclass.class_eval <<END_DEF
        def #{name}(value)
          @db.proxy_set #{db_key.inspect}, value
        end
END_DEF
    else
      @eigenclass.class_eval <<END_DEF
        def #{name}
          @db.proxy_get #{db_key.inspect}
        end
END_DEF
    end
    
    # The method was defined, now fire it off.
    send name, *args
  end
end  # class Pwnbus::ConfigDb::Db::Proxy

end  # class Pwnbus::Configdb::Db

end  # namespace Pwnbus::Configdb

end  # namespace Pwnbus
