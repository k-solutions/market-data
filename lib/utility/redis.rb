#!/usr/bin/env ruby
require 'yaml'
require 'uri'

require_relative 'config'

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