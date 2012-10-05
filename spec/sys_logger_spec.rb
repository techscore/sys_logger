# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SysLogger do
  before do
    Syslog.clear_lines
    @logger1 = SysLogger.new
    @logger2 = SysLogger.new
  end

  context "output logs" do
    it "debug" do
      @logger1.debug('DEBUG MESSAGE!%~{}#@')
      Syslog. last_line.message.should == 'DEBUG MESSAGE!%~{}#@'
      Syslog.last_line.level.should == Syslog::LOG_DEBUG
    end

    it "info" do
      @logger1.info('INFO MESSAGE!%~{}#@')
      Syslog. last_line.message.should == 'INFO MESSAGE!%~{}#@'
      Syslog.last_line.level.should == Syslog::LOG_INFO
    end

    it "warn" do
      @logger1.warn('WARN MESSAGE!%~{}#@')
      Syslog. last_line.message.should == 'WARN MESSAGE!%~{}#@'
      Syslog.last_line.level.should == Syslog::LOG_WARNING
    end

    it "error" do
      @logger1.error('ERROR MESSAGE!%~{}#@')
      Syslog. last_line.message.should == 'ERROR MESSAGE!%~{}#@'
      Syslog.last_line.level.should == Syslog::LOG_ERR
    end

    it "fatal" do
      @logger1.fatal('FATAL MESSAGE!%~{}#@')
      Syslog. last_line.message.should == 'FATAL MESSAGE!%~{}#@'
      Syslog.last_line.level.should == Syslog::LOG_CRIT
    end

    it "unknown" do
      @logger1.unknown('UNKNOWN MESSAGE!%~{}#@')
      Syslog. last_line.message.should == 'UNKNOWN MESSAGE!%~{}#@'
      Syslog.last_line.level.should == Syslog::LOG_ALERT
    end
    
    it "<<" do
      @logger1 << 'call << method!!'
      Syslog. last_line.message.should == 'call << method!!'
      Syslog.last_line.level.should == Syslog::LOG_ALERT
    end
  end

  it "facility" do
    facilities = %w(AUTH AUTHPRIV CRON DAEMON FTP KERN LPR MAIL NEWS SYSLOG USER UUCP LOCAL0 LOCAL1 LOCAL2 LOCAL3 LOCAL4 LOCAL5 LOCAL6 LOCAL7)
    loggers = {}
    facilities.each do |str|
      facility = OrgSyslog.const_get("LOG_#{str}")
      loggers[facility] = SysLogger.new(nil, facility)
    end
    loggers.each do |facility, logger|
      logger.info("facility: #{facility} log!")
      Syslog.last_line.facility.should == facility
    end
  end

  context "progname" do
    before do
      @logger1 = SysLogger.new('test1')
      @logger2 = SysLogger.new('test2')
    end
    
    it do
      @logger1.info("log message!!")
      Syslog.last_line.message.should == "test1: log message!!"

      @logger2.info("log message!!")
      Syslog.last_line.message.should == "test2: log message!!"

      @logger1.progname = "test3"
      @logger1.info("log message!!")
      Syslog.last_line.message.should == "test3: log message!!"
      
      @logger1.info("test4") {"log message!!"}
      Syslog.last_line.message.should == "test4: log message!!"
    end
  end

  context "log level" do
    before do
      @severities = %w(debug info warn error fatal unknown)
    end

    it "debug" do
      @logger1.level = SysLogger::DEBUG
      @severities.each {|sv| @logger1.send(sv, "#{sv.upcase} MESSAGE!") }
      Syslog.lines.size.should == 6
      Syslog.lines.map(&:severity).all?{|sv| sv >= SysLogger::DEBUG}.should be_true
    end
    
    it "info" do
      @logger1.level = SysLogger::INFO
      @severities.each {|sv| @logger1.send(sv, "#{sv.upcase} MESSAGE!") }
      Syslog.lines.size.should == 5
      Syslog.lines.map(&:severity).all?{|sv| sv >= SysLogger::INFO}.should be_true
    end
    
    it "warn" do
      @logger1.level = SysLogger::WARN
      @severities.each {|sv| @logger1.send(sv, "#{sv.upcase} MESSAGE!") }
      Syslog.lines.size.should == 4
      Syslog.lines.map(&:severity).all?{|sv| sv >= SysLogger::WARN}.should be_true
    end

    it "error" do
      @logger1.level = SysLogger::ERROR
      @severities.each {|sv| @logger1.send(sv, "#{sv.upcase} MESSAGE!") }
      Syslog.lines.size.should == 3
      Syslog.lines.map(&:severity).all?{|sv| sv >= SysLogger::ERROR}.should be_true
    end

    it "fatal" do
      @logger1.level = SysLogger::FATAL
      @severities.each {|sv| @logger1.send(sv, "#{sv.upcase} MESSAGE!") }
      Syslog.lines.size.should == 2
      Syslog.lines.map(&:severity).all?{|sv| sv >= SysLogger::FATAL}.should be_true
    end

    it "unknown" do
      @logger1.level = SysLogger::UNKNOWN
      @severities.each {|sv| @logger1.send(sv, "#{sv.upcase} MESSAGE!") }
      Syslog.lines.size.should == 1
      Syslog.last_line.severity.should == SysLogger::UNKNOWN
    end
  end
  
  it "silence" do
    @logger1.level = SysLogger::DEBUG
    @logger1.error('error message!')
    Syslog.lines.count.should == 1
    Syslog.clear_lines
    @logger1.silence(SysLogger::ERROR) do |logger|
      @logger1.error('error message!')
      Syslog.lines.count.should == 1
      Syslog.clear_lines
      
      logger.warn('warn message!')
      Syslog.lines.should be_empty
      
      logger.error('error message!')
      Syslog.lines.count.should == 1
      Syslog.clear_lines
    end
  end
  
end
