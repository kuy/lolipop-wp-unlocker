#!/usr/bin/env ruby

require 'yaml'
require 'tempfile'
require 'net/http'
require 'net/ftp'

cfg = nil
begin
  cfg = YAML.load_file File.expand_path '../config.yml', __FILE__
rescue Errno::ENOENT
  warn 'ERROR: config.yml not found'
  exit 1
end

Net::FTP.open cfg['host'] do |ftp|
  ftp.login cfg['username'], cfg['password']
  ftp.passive = true

  lines = Tempfile.open 'lwu' do |tmp|
    ftp.getbinaryfile '.htaccess', tmp.path
    tmp.readlines
  end

  current_ip = Net::HTTP.get('ipinfo.io', '/ip').strip!
  lines.each do |line|
    if line.include? current_ip
      puts "Your IP address #{current_ip} is already allowed in .htaccess file, exit"
      exit
    end
  end

  marker_pos = nil
  lines.each_with_index do |line, i|
    if line.start_with? 'Deny  from all'
      marker_pos = i
      break
    end
  end

  lines.insert marker_pos + 1, "Allow from #{current_ip}\n"

  updated_path = Tempfile.open 'lwu' do |tmp|
    tmp.write lines.join('')
    tmp.path
  end

  ftp.putbinaryfile updated_path, '.htaccess'

  puts "Your IP address #{current_ip} is now allowed"
end
