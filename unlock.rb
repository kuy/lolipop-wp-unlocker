#!/usr/bin/env ruby

require 'yaml'
require 'net/http'
require 'net/ftp'

cfg = YAML.load_file File.expand_path '../config.yml', __FILE__

Net::FTP.open cfg['host'] do |ftp|
  ftp.login cfg['username'], cfg['password']
  ftp.passive = true
  ftp.getbinaryfile '.htaccess', '_htaccess'

  lines = nil
  open('_htaccess') do |f|
    lines = f.readlines
  end

  pos = nil
  lines.each_with_index do |line, i|
    if line.start_with? 'Deny  from all'
      pos = i
      break
    end
  end

  ip = Net::HTTP.get('ipinfo.io', '/ip').strip!
  lines.insert pos + 1, "Allow from #{ip}\n"

  open('_htaccess_updated', 'w') do |f|
    f.write lines.join('')
  end

  # ftp.delete '.htaccess'
  ftp.putbinaryfile '_htaccess_updated', '.htaccess'
end
