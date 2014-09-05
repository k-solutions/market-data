#!/usr/bin/env ruby
require 'yaml'
require 'uri'
require_relative '../init'

# get transformed options for daemons in current environment
module Utility
  
  PATH_EXPAN = '../../../'
  ROOT_DIR   = File.expand_path(PATH_EXPAN , __FILE__ ) unless defined? ROOT_DIR
  KILL_SIGNALS        = %w(INT TERM)
  
  # creates a signals trapping for the kill or kill USR 
  def self.signals_trap
    KILL_SIGNALS.each do |sig|
      trap( sig ) do
        yield if block_given?
        
        trap sig, 'DEFAULT'
        Process.kill sig, 0 # exit 0
      end
    end
  end
  
  class Config
    class << self
      def get filename
        raise ArgumentError.new "Missing relative file name" unless filename
        root_dir ||= defined?( ROOT_DIR ) ? ROOT_DIR : File.expand_path( PATH_EXPAN, __FILE__ )
        res = File.join( root_dir, filename )
        raise ArgumentError.new "Missing file or file not readable!" unless File.readable? res
        
        res
      end
    end
  end
  
  class Parser
   class << self
    def get config_file, config_key = nil, merge = false
     raise ArgumentError.new "Missing config file param!" unless config_file 
     config_file = Config.get config_file unless File.readable?( config_file )
     raise ArgumentError.new "Bad path or file unreadable for #{config_file}!" unless config_file or File.readable?( config_file )
     
     options = YAML.load_file( config_file )
     config_key ||= ENV['RAILS_ENV'] if ENV['RAILS_ENV']
     
     if config_key
      raise ArgumentError.new "Make sure you have #{config_key} key in the #{config_file}" unless options[ config_key ]
      
      merge ? options.rmerge( options[ config_key ] ) : options[ config_key ]
     else
      options
     end
    end
   end
  end
end