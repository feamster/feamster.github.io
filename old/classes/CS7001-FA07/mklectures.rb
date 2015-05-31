#!/usr/bin/env ruby

##
# Convert a flat text file of lectures to HTML
##

$LOAD_PATH << File.dirname(__FILE__)

require 'time'
require 'bibparse'
require 'yaml'

LECTUREFILE = 'lectures.txt'
BIBFILE = "./class.bib"
SLIDETYPES = ["pdf", "ps", "html", "ppt"]
SLIDEDIR = "lectures"

class LecPrinter

  def initialize(lecfile, bibparse=nil)
    @lecfile = lecfile
    @bp = bibparse
    @start_time = nil
    @end_time = nil
    @year = nil
    @instructor = nil
    @term = nil
    @summary = nil

    readlecs(lecfile)
  end
  

  def print_ical
    out = File.new("#{@class_short}.ics", "w+")
    out.puts "BEGIN:VCALENDAR\nVERSION:2.0\nX-WR-CALNAME:#{@conf["CLASS_SHORT"].to_s.downcase}"
    out.puts "X-WR-TIMEZONE:US/Eastern"
    out.puts "CALSCALE:GREGORIAN"

    @lectures.each { |l|

      next if l["type"] != "lecture"
      
      out.puts "BEGIN:VEVENT"
      out.puts "DTSTART;TZID=US/Eastern:#{l['stime'].strftime("%Y%m%dT%H%M00")}"
      out.puts "DTEND;TZID=US/Eastern:#{l['etime'].strftime("%Y%m%dT%H%M00")}"
      out.puts "SUMMARY:#{@summary}"
      out.puts "DESCRIPTION:#{l["T"]}"
      out.puts "END:VEVENT"
    }

    out.puts "END:VCALENDAR"
  end

  def print_html
    print IO.read("syllabus.head")

    rowcount = 0
    @lectures.each { |l|


      ltype = l["type"]


      if (l["type"] == "lecture")
	# allow a wash on alternating rows
	if (@conf["ALTERNATE"] == 'row') 
	  if ((rowcount & 1) == 1)
	    ltype += " alt"
	  end
	  rowcount += 1
	elsif (@conf["ALTERNATE"] == 'week') 
	  weeknum = l['stime'].strftime("%U")
	  if ((weeknum.to_i & 1) == 1)
	    ltype += " alt"
	  end
	end
      end

      puts "<tr class=\"#{ltype}\">"

      if (l["type"] == "lechead")
	
	puts %Q{ <td class="#{ltype}" colspan="#{@conf["HEADSPAN"]}">#{l["T"]}</td>}
	puts "</tr>";
	next
      end


      


      if (@conf["SHOW_LECNUM"])
	if l["type"] == "lecture"
	  puts " <td>#{l["lecnum"]}</td>"
	else
	  puts " <td></td>"
	end
      end
      puts " <td>#{l["date"]}</td>"
      
      if (@conf["SHOW_INSTRUCTOR"])
	puts " <td>#{l["I"]}</td>"
      end

      tspan = ""
      if (l["TSPAN"])
          tspan = " colspan=\"#{l["TSPAN"]}\""
      end
      puts " <td#{tspan}>#{l["T"]} <br />"

      if (l["S"])
	SLIDETYPES.each { |ext|
	  filename = SLIDEDIR + "/" + l["S"] + "." + ext
	  if (FileTest.exists?(filename))
	    print "[<a href=\"#{filename}\">#{ext}</a>] "
	  end
	}
      end
      
      if (l["V"] && l["V"].to_s.length > 0)
	vcount = 1
	l["V"].to_s.split.each { |v|
	  print "[<a href=\"#{@videobase.sub("VIDEOID", v)}\">Video #{vcount}</a>] "
	  vcount += 1
	}
      end
      
      puts " </td>"
      
      # Notes
      if (!l["TSPAN"] || l["TSPAN"].to_i <= 1)
	  if (l["N"] =~ /Due/i && @conf["HIGHLIGHT_DUE"]) 
	      puts " <td class=\"due\">#{l["N"]}</td>"
	  else
	      puts " <td>#{l["N"]}</td>"
	  end
      end
      
      if (!l["TSPAN"] || l["TSPAN"].to_i <= 2)
      # Readings
	  print " <td>#{l["R"]} "
      
	  # Links for Readings
	  
	  if (l["RL"] && l["RL"].length > 0)
	      rlcount = 1
	      l["RL"].split.each { |rl|
			      print "<a href=\"#{@readingbase}#{rl}-abstract.html\">#{rl}</a> "
			  }
	  end
      
	  # Bibtex-Based Links for Readings
	  if (l["RB"] && l["RB"].length > 0)
	      l["RB"].split.each { |rb|
			      
			      # ref is [refname, url]
  	      ref = rb.split('::')
	  
	      url = ref[1]
	      if (url !~ /http/) 
	        url = sprintf("%s/%s", @readingbase, url)
	      end
	  
	      @bp.setURL(ref[0],url)
	  
	      # add to the reading list
	      @bp.addToList(ref[0], l)
	  
	      print "<a href=\"#{url}\">#{ref[0]}</a> "
	  
	    }
	  end
          puts " </td>"
      end
      
      puts "</tr>"
    }

    puts "</table>"
    
    print IO.read("syllabus.tail")
  end
    
  def readlecs(lecfile)
    @conf = YAML::load(File.open(lecfile))

    @year = @conf['YEAR']
    @summary = @conf['SUMMARY']
    @class_short = @conf['CLASS_SHORT'].to_s.downcase + '-' +
      @conf['TERM'] + @conf['YEAR'].to_s
    @instructor = @conf['INSTRUCTOR']
    @videobase = @conf['VIDEOBASE']
    @readingbase = @conf['READINGBASE']
    @start_time = @conf['START_TIME']
    @end_time = @conf['END_TIME']

    lecnum = 1
  
    @lectures = Array.new
    @conf['LECTURES'].each { |l|

      if (l.class == String)
	lec = Hash.new
	lec["type"] = "lechead"
	lec["T"] = l.dup
      else

	key = l.keys[0]
        if (l[key] != nil)
          lec = l[key].dup
        else
          lec = Hash.new
        end

	lec["type"] ||= "lecture"

	if (lec["type"] == "lecture") 
	  lec["lecnum"] = lecnum
          lecnum = lecnum + 1
	end

	lec["year"] = @year
	m, d = key.split("/") # obtuse.  we store in hash keyed by date
	lec["day"] = d
	lec["month"] = m
	lec["START"] ||= @start_time
	lec["END"] ||= @end_time
	lec["I"] ||= @instructor

	shour, smin = lec["START"].split(":")
	ehour, emin = lec["END"].split(":")
	lec["stime"] = Time.local(lec["year"].to_i, lec["month"].to_i, lec["day"].to_i,
			   shour.to_i, smin.to_i, 0)
	lec["etime"] = Time.local(lec["year"].to_i, lec["month"].to_i, lec["day"].to_i,
			   ehour.to_i, emin.to_i, 0)
	lec["date"] = lec["stime"].strftime("%a %m/%d")
      end

      @lectures.push(lec)
    }
  end
end

bp = nil
if (FileTest.exists?(BIBFILE))
  bp = BibParse.new(BIBFILE)
end
lp = LecPrinter.new(LECTUREFILE, bp)

lp.print_html
lp.print_ical
    
if (bp) 
  bp.printReadingList("readinglist.html",
		      "readinglist.head",
		      "readinglist.tail")
end
