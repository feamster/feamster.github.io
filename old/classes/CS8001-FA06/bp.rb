#!/usr/bin/env ruby

$LOAD_PATH << (File.dirname(__FILE__) + '/include/')
$LOAD_PATH << File.dirname(__FILE__)
$INC = [File.dirname(__FILE__)]

require 'yaml'
require 'weblib'
require 'ostruct'
require 'parsedate'

TALK_TEMPLATE = File.read("talk_skel.srhtml")
INDEX_TEMPLATE = File.read("index.srhtml")

class Sem
    attr_reader :talk
    attr_accessor :htmlfile
    attr_reader :date
    def initialize(filename)
        @date = 0
        @talk = OpenStruct.new(YAML.load_file(filename))
        if (@talk.Date)
	    (d, m, y) = ParseDate.parsedate(@talk.Date)
	    @date = Time.gm(y, m, d)
	end
    end
    def create_html(semlist = nil)
      b = binding
      ERB.new(TALK_TEMPLATE, 0, "").result b
    end
end

sems = Array.new
olds = Array.new

Dir['detail/*.txt'].each { |semfile|
    sem = Sem.new(semfile)
    htmlfile = semfile.sub(/txt$/, "html")
    sem.htmlfile = htmlfile
    if (sem.date > (Time.now - 86400))
      sems << sem
    else
      olds << sem
    end
}

SEMS = sems.sort_by { |sem| sem.date }
OLDS = olds.sort_by { |sem| sem.date }.reverse

sems.each do |sem|
    File.open(sem.htmlfile, "w") do |f|
        f.print sem.create_html(SEMS)
    end
end

olds.each do |sem|
    File.open(sem.htmlfile, "w") do |f|
        f.print sem.create_html
    end
end


b = binding
File.open("index.html", "w") do |f|
    f.print ERB.new(INDEX_TEMPLATE, 0, "").result(b)
end
