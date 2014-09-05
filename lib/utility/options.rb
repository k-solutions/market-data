#!/usr/bin/env ruby
require 'yaml'
require 'uri'

ROOT_DIR = File.expand_path( "..", File.dirname(__FILE__) ) unless defined? ROOT_DIR
ENV['RAILS_ENV'] ||= 'development'
# = Hash Recursive Merge
#
# Merges a Ruby Hash recursively, Also known as deep merge.
# Recursive version of Hash#merge and Hash#merge!.
# 
# Category::    Ruby
# Package::     Hash
# Author::      Simone Carletti <weppos@weppos.net>
# Copyright::   2007-2008 The Authors
# License::     MIT License
# Link::        http://www.simonecarletti.com/
# Source::      http://gist.github.com/gists/6391/
#module HashRecursiveMerge
class ::Hash
 def rmerge!(other_hash)
  merge!(other_hash) { |key, oldval, newval| oldval.class == self.class ? oldval.rmerge!(newval) : newval }
 end
 
 def rmerge(other_hash)
  r = {}
  merge(other_hash) { |key, oldval, newval| r[key] = oldval.class == self.class ? oldval.rmerge(newval) : newval }
 end
end

# get transformed options for daemons in current environment
module Utility
  class LazyConnection < BasicObject
    # BasicObject requires ruby 1.9
    # http://www.ruby-doc.org/core-1.9.2/BasicObject.html

    def initialize(&lazy_connection_block)
      @lazy_connection_block = lazy_connection_block
    end

    def method_missing(method, *args, &block)
      @lazy_proxy_obj ||= @lazy_connection_block.call # evaluate the real receiver
      @lazy_proxy_obj.send(method, *args, &block) # delegate unknown methods to the real receiver
    end
  end
  
  class Config
    class << self
      def get filename
        raise ArgumentError.new "Missing relative file name" unless filename
        root_dir ||= defined?( ROOT_DIR ) ? ROOT_DIR : File.expand_path( File.dirname(__FILE__) + '/../' )
        res = File.join( root_dir, filename )
        raise ArgumentError.new "Missing file or file not readable!" unless File.readable? res
        
        res
      end
    end
  end
  
  class Parser
   class << self
    def get config_file, config_key = nil, merge = false
     raise ArgumentError.new "Missing #{config_file}" unless config_file or File.readable?( config_file )
     
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
  
  # get transformed options for daemons in current environment
  class Daemons
    CONFIG_FILE =  Config.get '/config/daemons.yml'
    OPTIONS     =  Parser.get CONFIG_FILE
    DEFAULTS = {   :dir_mode   => :normal,
                   :dir        => 'tmp/pids',
                   :log_output => true }
    class << self
      # get transformed options for daemons in current environment
      def get
        raise ArgumentError.new "Add config setting for environment #{ ENV['RAILS_ENV'] } in #{CONFIG_FILE}" if OPTIONS.empty?
        
        options = OPTIONS['options'] || DEFAULTS
        pid_dir = Config.get "/#{ options[:dir] || DEFAULTS[:dir] }"
        FileUtils.mkdir_p( pid_dir )
        
        options.update( :dir => pid_dir )
      end
    end
  end

  class Redis
   REDIS_ROLE  = :pubsub
   CONFIG_FILE = Config.get '/config/redis.yml'
   
   class << self
     # get transformed options for daemons in current environment
     def get role = REDIS_ROLE
       @options ||= Parser.get CONFIG_FILE
       # raise ArgumentError.new "Add config setting for environment #{ ENV['RAILS_ENV'] } in #{CONFIG_FILE}" if !OPTIONS or OPTIONS.empty? # [ENV['RAILS_ENV']]
       # raise ArgumentError.new "Setup the proper options in #{CONFIG_FILE}" unless @options[ :redis ]
       # @options ||= ENV_OPTIONS ?  ENV_OPTIONS : OPTIONS[ :redis ]
       raise ArgumentError.new "Setup redis roles options in #{CONFIG_FILE}" unless @options[ role ] # or @options[ REDIS_ROLE ][ :url ]

       options = @options[ role ]

       # construct host and port TODO: and redis instance from url
       if options[:url]
         redis_uri = URI( options[:url] )
         options[:host]  = options['host'] = redis_uri.host unless options['host'] or options[:host]
         options[:port]  = options['port'] = redis_uri.port unless options['port'] or options[:port]
       end

       options
     end

     def get_connection role = :redisrb, lazy = false, driver = :hiredis
       res = case role
       when :hiredis
         require 'hiredis' unless defined? Hiredis
         options,con = get( role ), ::Hiredis::Connection.new
         con.connect(options[:host], options[:port])
         con 
       when :celluloid
         require 'celluloid/redis'
         ::Redis.new get( role ).update( :driver => :celluloid )
       else # default to hiredis connection using redis-rb gem
         require "redis" unless defined? Redis
         ::Redis.new get( role ).update( :driver => driver )
       end
     # TODO: rescue Redis(rb) connection errors
       lazy ? LazyConnection.new { res } : res
     rescue Hiredis::Connection::EOFError => e
       puts "Hiredis Redis connection error #{e}"
     end
   end
  end
end