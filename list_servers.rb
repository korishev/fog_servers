#!/usr/bin/env ruby
require 'fog'
require 'erb'
require 'json'
require 'terminal-table'
require './lib/text_formatter'
require './lib/html_formatter'

class ServerInfo

  def initialize
    @keys = YAML.load(File.read("keys.yaml"))
  end

  def server_group(group_name)
    group = group_name.downcase
    server_group = []
    server_group << [group_name, Fog::Compute.new(provider: "AWS", aws_secret_access_key: @keys[group_name]["aws_secret_access_key"], aws_access_key_id: @keys[group_name]["aws_access_key_id"]).servers ]
    server_group
  end

  def display(group, formatter)
    group = server_group(group)
    formatter.new.format(group)
  end
end

ServerInfo.new.display(ARGV[0], TextFormatter)
