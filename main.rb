#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'optparse'
require 'json'
require 'open3'
require 'shellwords'

def gem_install
  gem_install = 'gem install bundler -v $(cat Gemfile.lock | tail -1 | tr -d " ")'
  Open3.popen2e(gem_install) do |i, oe, t|
    oe.sync = true
  end
end

def bundle_install
  command = ["bundle install"]
  command << "--jobs=4"
  command << "--retry=3"
  command << "--path=.bundle"
  command << "--user"
  command << "--local"

  exit_status = nil
  Open3.popen2e(command.join(" ")) do |i, oe, t|
    oe.sync = true
    exit_status = t.value
  end
  if exit_status.exitstatus != 0
    command.pop
    Open3.popen2e(command.join(" ")) do |i, oe, t|
      oe.sync = true
      exit_status = t.value
    end
  end
  if exit_status.exitstatus != 0
    raise StandardError, "[!] Exit status of command `#{command}` was #{exit_status.exitstatus} instead of 0."
  end
end

########################################################
# @!group Main: 脚本初始入口
########################################################
options = {}
OptionParser.new do |opt|
  opt.on('--encode ENCODE') { |o| options[:encode] = o }
  opt.on('--decode DECODE') { |o| options[:decode] = o }
  opt.on('--encode64 STR') { |o| options[:encode64] = o }
  opt.on('--decode64 STR') { |o| options[:decode64] = o }
end.parse!

def alfred_output(title, subtitle, arg)
  {
    "items" => [
      {
        "title" => title,
        "subtitle" => subtitle,
        "arg" => arg,
        "icon" => 'icon.png'
      }
    ]
  }.to_json
end

require 'cgi'
require 'base64'

encode_str = options[:encode].to_s
unless encode_str.empty?
  result = CGI.escape(encode_str)
end

decode_str = options[:decode].to_s
unless decode_str.empty?
  result = CGI.unescape(decode_str)
end

base64_str = options[:encode64].to_s
unless base64_str.empty?
  result = Base64.encode64(base64_str)
end

unbase64_str = options[:decode64].to_s
unless unbase64_str.empty?
  result = Base64.decode64(unbase64_str)
end

puts alfred_output(result, "", result)
