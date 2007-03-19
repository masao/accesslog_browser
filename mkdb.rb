#!/usr/bin/env ruby
# $Id$

require 'ftools'
begin
   $:.unshift(ENV["HOME"] + "/lib/ruby")
   require 'sqlite3'
rescue LoadError
   require 'dbi'
end

require "log.rb"
include ApacheLog

DBNAME = "accesslog.db"
DBNAME_TMP = DBNAME + ".tmp"
File.rm_f(DBNAME_TMP) if FileTest.exist? DBNAME_TMP

CREATE_TABLE = <<EOF
CREATE TABLE accesslog (
 addr TEXT,
 user TEXT,
 ugroup TEXT,
 datetime DATETIME,
 request TEXT,
 status TEXT,
 byte TEXT,
 referer TEXT,
 ua TEXT
    );
EOF

if FileTest.exist? DBNAME
   File.cp(DBNAME, DBNAME + ".old", true)
end

#dbh = DBI.connect("dbi:SQLite:#{DBNAME_TMP}")	# For DBI
#dbh['AutoCommit'] = false
dbh = SQLite3::Database.new(DBNAME_TMP)		# For SQLite3

dbh.transaction do
   #dbh.do(CREATE_TABLE)	# For DBI
   dbh.execute(CREATE_TABLE)	# For SQLite3
   sth = dbh.prepare("INSERT INTO accesslog VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)");
   logfile = open(File.basename(DBNAME) + ".log.#{Time.now.strftime("%Y%m%d")}", "w")
   parse( ARGF ) do |addr, user, group, datetime, request, status, byte, referer, ua|
      sth.execute( addr, user, group, datetime, request, status, byte, referer, ua )
      logfile.puts [ addr, user, group, datetime, request, status, byte, referer, ua ].join(" ")
   end
   logfile.close
end

File.mv(DBNAME_TMP, DBNAME, true)
