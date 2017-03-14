#!/usr/bin/env ruby
#whois against all domains provided in list.
#Usage: ./bulkwhois.rb /path/to/domains.txt

require 'tty-command'
require 'logger'
require 'colorize'
require 'threadify'
require 'csv'

domain_list = File.readlines(ARGV[0]).map(&:chomp &&:strip)
@domains = []

def command
  @log = Logger.new('debug.log')
  cmd  = TTY::Command.new(output: @log)
end

def whois(domain_list)
  dom_hash = {}
  
    domain_list.threadify do |domain|
      out, err = command.run!("whois #{domain}")
      puts "Whois completed for: #{domain.upcase}".green.bold
        dom_hash[:domain]       = domain
        dom_hash[:registrar]    = out.scan(/(?<=Registrar:\s)(.*)/).join("\r") rescue ""
          if dom_hash[:registrar].empty?
            dom_hash[:registrar] = out.scan(/(?<=Organization:\s)(.*)/).join("\r") rescue ""
          end
        dom_hash[:namesrv]      = out.scan(/(?<=Name Server:\s)(.*)/).join("\r") rescue ""
        dom_hash[:created]      = out.scan(/(?<=Creation Date:\s)(.*)/).join("\r") rescue ""
        dom_hash[:updated]      = out.scan(/(?<=Updated Date:\s)(.*)/).join("\r") rescue ""
        dom_hash[:expires]      = out.scan(/(?<=Expiration Date:\s)(.*)/).join("\r") rescue ""
        dom_hash[:reg_name]     = out.scan(/(?<=Registrant Name:\s)(.*)/).join("\r") rescue ""
        dom_hash[:reg_org]      = out.scan(/(?<=Registrant Organization:\s)(.*)/).join("\r") rescue ""
        dom_hash[:reg_city]     = out.scan(/(?<=Registrant City:\s)(.*)/).join("\r") rescue ""
        dom_hash[:reg_phone]    = out.scan(/(?<=Registrant Phone:\s)(.*)/).join("\r") rescue ""
        dom_hash[:reg_email]    = out.scan(/(?<=Registrant Email:\s)(.*)/).join("\r") rescue ""
        dom_hash[:tech_name]    = out.scan(/(?<=Tech Name:\s)(.*)/).join("\r") rescue ""
        dom_hash[:tech_phone]   = out.scan(/(?<=Tech Phone:\s)(.*)/).join("\r") rescue ""
        dom_hash[:tech_email]   = out.scan(/(?<=Tech Email:\s)(.*)/).join("\r") rescue ""

        @domains << dom_hash.dup
  end
end

def create_file
  Dir.mkdir("#{Dir.home}/Documents/bulkwhois_out/") unless File.exists?("#{Dir.home}/Documents/bulkwhois_out/")
  @file    = "bulkwhois_#{Time.now.strftime("%d%b%Y_%H%M%S")}"
  @csvfile = File.new("#{Dir.home}/Documents/bulkwhois_out/#{@file}.csv", 'w+')
  puts "Output written to #{@csvfile.path}".light_blue.bold
end

  def write_to_csv
    CSV.open(@csvfile, 'w+') do |csv|
      csv << @domains.first.keys
      @domains.each do |record|
        csv << record.values
      end
    end
  end

run = whois(domain_list)
create_file
write_to_csv