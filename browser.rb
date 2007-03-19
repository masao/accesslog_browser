#!/usr/bin/env ruby
# $Id$

$KCODE = "euc"

require 'jcode'
require 'cgi'
begin
   require 'sqlite3'
   DBTYPE = SQLite3::Database
rescue LoadError
   require 'dbi'
   DBTYPE = DBI
end
#STDERR.puts DBTYPE

begin
   require 'erb'
   ERbLight = ERB
rescue LoadError
   require 'erb/erbl'
end

ACCESSLOG_BROWSER_VERSION = '$Id$'

class CGI
   def valid?( arg )
      self.params[arg][0] and self.params[arg][0].length > 0
   end
end

class AccessLogBrowser
   attr_reader :date

   def initialize( cgi, rhtml )
      @cgi, @rhtml = cgi, rhtml
      @date = @cgi.params['date'][0] if @cgi.valid?( 'date' )
   end

   include ERbLight::Util
   def do_eval_rhtml
      ERbLight::new( open( @rhtml ).read ).result( binding )
   end
end

if $0 == __FILE__
   begin
      cgi = CGI.new
      log_browser = AccessLogBrowser.new(cgi, "tmpl/index.rhtml")

      cgi.out("text/html; charset=EUC-JP"){ log_browser.do_eval_rhtml }

   rescue Exception
      if cgi then
         print cgi.header( 'type' => 'text/plain' )
      else
         print "Content-Type: text/plain\n\n"
      end
      puts "#$! (#{$!.class})"
      puts ""
      puts $@.join( "\n" )
   end
end
