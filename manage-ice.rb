#!/usr/bin/env ruby
BASE = File.expand_path(File.dirname(__FILE__))
require File.join(BASE, "interfaces", "ice.rb")
require File.join(BASE, 'helpers')
require 'rubygems'
require 'json'

class UnknownCommandException < Exception; end

def server_command(meta, id, command = nil, *args)
	server = meta.get_server(id)
	case command
	when "set"
		key = args.shift
		val = args.join " "
		server[key] = val
		puts "Set #{key} = #{val}"
	when "start"
		server.start
	when "stop"
		server.stop
	when "restart"
		server.restart!
	when "destroy"
		server.destroy!
	when "supw"
		pw = args.shift
		raise "Cannot set a blank superuser password" if pw.nil? or pw == ""
		server.setSuperuserPassword(pw)
	when "", "config", nil
	  if !args.empty? && args.include?("-json")
	    puts JSON.generate server.config
    else
		  server.config.each do |key, val|
  			pt key, val.split("\n").first
		  end
	  end
	else
		raise UnknownCommandException 
	end
end

def meta_command(meta, command = nil, *args)
	case command
	when "list"
	  serverHash = Hash.new
    meta.list_servers.each do |server|
			serverHash[server.id] = server.isRunning
	  end

	  #output
	  if !args.empty? && args.include?("-json")
	    puts JSON.generate serverHash
	  else
		  pt "Server ID", "Running", 2
  		pt "---------", "------", 2
		
  		serverHash.each do |key, value| 
  		  pt key, value, 2 
		  end
	  end
	when "new"
		port = args.first
		port = nil if !port.nil? and port.to_i == 0
		server = meta.new_server(port)
		puts "New server: ID #{server.id} added"
	else
		raise UnknownCommandException 
	end
end

begin
	meta = Murmur::Ice::Meta.new
	# For a Glacier2 connection:
	# meta = Murmur::Ice::Meta.new "host.com", 4063, "user", "pass"
	
	if (ARGV[0] || 0).to_i != 0 then
		server_command(meta, *ARGV)
	else
		meta_command(meta, *ARGV)
	end
rescue UnknownCommandException
	help
end
