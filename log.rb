#!/usr/bin/env ruby
# $Id$

require "time"

class Time
   def to_iso8601
      self.strftime( "%Y-%m-%dT%H:%M:%S" )
   end
end

module ApacheLog
   MonthValue = {
      'JAN' => 1, 'FEB' => 2, 'MAR' => 3, 'APR' => 4, 'MAY' => 5, 'JUN' => 6,
      'JUL' => 7, 'AUG' => 8, 'SEP' => 9, 'OCT' =>10, 'NOV' =>11, 'DEC' =>12
   }
   # ct501026.inktomisearch.com - - [11/Mar/2007:04:05:25 +0900] "GET /cgi-bin/retrieve/sr_makehtml.cgi?U_CHARSET=EUC-JP&CGILANG=japanese&HTMLFILE=sr_EC.html HTTP/1.0" 200 14626 "-" "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
   def parse( io )
      io.each do |line|
         if /^([^\s]+) ([^\s]+) ([^\s]+) \[([^\]]+)\] "([^\"]+)" (\d+) (\d+|-) "([^\"]+)" "(.*)"$/ =~ line
            addr, user, group, datetime, request, status, byte, referer, ua,= $~.to_a[1 .. -1]
            yield addr, user, group, timeparse( datetime ), request, status, byte, referer, ua
         else
            STDERR.puts "err: " << line
         end
      end
   end
   def timeparse( time_str )
      "11/Mar/2007:04:05:25 +0900"
      #     d,      m_str  y,          h,    M,     s         tz
      if /^(\d\d)\/(...)\/(\d\d\d\d):(\d\d):(\d\d):(\d\d) \+(\d\d\d\d)$/ =~ time_str
         d, mon_str, y, h, m, s, tz = $~[1 .. -1]
         Time.mktime(s, m, h, d, Time::MonthValue[mon_str.upcase], y, nil, nil, false, tz)
      end
   end
end

if $0 == __FILE__
   include ApacheLog
   parse( ARGF ) do |addr, user, group, datetime, request, status, byte, referer, ua|
      puts [ addr, user, group, datetime.to_iso8601, request, status, byte, referer, ua ].join("\t")
   end
end
