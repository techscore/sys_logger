# coding: utf-8
if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/vendor/'
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'sys_logger'

OrgSyslog = Syslog
module SyslogMock
  include Syslog::Constants

  class LogLine
    attr_reader :priority, :message

    def self.create(priority, format, *args)
      new(priority, format%args)
    end

    def initialize(priority, message)
      @priority, @message = priority, message
    end

    def facility
      ~0b111 & @priority
    end

    def severity
      SysLogger::SEVERITY_MAP.invert[level]
    end

    def level
      0b111 & @priority
    end

    def to_s
      @message
    end
  end

  module_function

  def lines
    @@log_lines ||= []
  end

  def last_line
    lines.last
  end

  def clear_lines
    lines.clear
  end

  def log(priority, format, *args)
    lines << LogLine.create(priority, format, *args)
  end

  def method_missing(name,*args, &block)
    OrgSyslog.send(name, *args, &block)
  end
end

begin
  org_verbose = $VERBOSE
  $VERBOSE = nil
  Syslog = SyslogMock
ensure
  $VERBOSE = org_verbose
end
