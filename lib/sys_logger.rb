# coding: utf-8
require 'syslog'
require 'logger'

class SysLogger
  VERSION = '1.0.0'

  include Syslog::Constants
  include Logger::Severity

  SEVERITY_MAP = {
    DEBUG     => Syslog::LOG_DEBUG,
    INFO      => Syslog::LOG_INFO,
    WARN      => Syslog::LOG_WARNING,
    ERROR     => Syslog::LOG_ERR,
    FATAL     => Syslog::LOG_CRIT,
    UNKNOWN   => Syslog::LOG_ALERT,
  }

  class << self
    # Syslogモジュールに移譲するメソッドを作成する
    Syslog.singleton_methods(false).reject{|method| method.to_s == "inspect"}.each do |method|
      define_method(method) {|*args| Syslog.send(method, *args)}
    end
  end

  attr_accessor :progname, :facility, :level
  alias sev_threshold level
  alias sev_threshold= level=


  # ロガーインスタンスを生成します
  #
  # ==== 引数
  # progname: ログに出力するプログラム名
  # facility: ファシリティ
  # level   : ログレベル(SysLogger::DEBUG, SysLogger::INFO, SysLogger::WARN, SysLogger::ERROR, SysLogger::FATAL, SysLogger::UNKNOWN)
  def initialize(progname = nil, facility = nil, level = SysLogger::DEBUG)
    @progname, @facility, @level = progname, facility, level
    Syslog.open unless Syslog.opened?
  end

  # ログを出力します。
  # severityはUNKNOWN扱いになります。
  #
  # ==== 引数
  # message: ログに出力するメッセージ
  #
  # ==== 戻り値
  # self
  #
  def <<(message)
    add(UNKNOWN, message)
    self
  end

  # メッセージをログに記録します。
  # ブロックを与えた場合はブロックを評価した返り値をメッセージとしてログに記録します。 ユーザがこのメソッドを直接使うことはあまりありません。 
  #
  # ==== 引数
  # severity: ログレベル。SysLogger クラスで定義されている定数を指定します。 この値がレシーバーに設定されているレベルよりも低い場合、 メッセージは記録されません。
  # message: ログに出力するメッセージを文字列か例外オブジェクトを指定します。 省略すると nil が用いられます。
  # progname: ログメッセージと一緒に記録するプログラム名を指定します。 省略すると nil が使用されますが、実際には内部で保持されている値が使用されます。 
  #
  # ==== 戻り値
  # true
  #
  def add(severity, message = nil, progname = nil)
    severity ||= UNKNOWN
    return true if severity < level
    progname ||= @progname
    if message.nil?
      if block_given?
        message = yield
      else
        message = progname
        progname = @progname
      end
    end
    priority = SEVERITY_MAP[severity]
    priority |= facility if @facility
    progname = progname.to_s
    if progname.empty?
      Syslog.log(priority, '%s', message.to_s)
    else
      Syslog.log(priority, '%s: %s', progname, message.to_s)
    end
    true
  end
  alias log add

  # 現在の Logger オブジェクトが DEBUG 以上のログレベルのメッセージを記録するなら 真を返します。 
  def debug?; @level <= DEBUG; end
  # 現在の Logger オブジェクトが INFO 以上のログレベルのメッセージを記録するなら 真を返します。 
  def info?;  @level <= INFO ; end
  # 現在の Logger オブジェクトが WARN  以上のログレベルのメッセージを記録するなら 真を返します。 
  def warn?;  @level <= WARN ; end
  # 現在の Logger オブジェクトが ERROR 以上のログレベルのメッセージを記録するなら 真を返します。 
  def error?; @level <= ERROR; end
  # 現在の Logger オブジェクトが FATAL 以上のログレベルのメッセージを記録するなら 真を返します。 
  def fatal?; @level <= FATAL; end
  
  #  DEBUG 情報を出力します。
  # 
  # ==== 詳細
  # ブロックを与えなかった場合は、progname をメッセージとしてログを出力します。
  # ブロックを与えた場合は、ブロックを評価した結果をメッセージとして ログを出力します。
  # 引数とブロックを同時に与えた場合は、progname をプログラム名、ブロックを評価した 結果をメッセージとしてログを出力します。
  # 
  # ==== 引数
  # progname:  ブロックを与えない場合は、メッセージとして文字列または例外オブジェクトを指定します。 ブロックを与えた場合は、プログラム名を文字列として与えます。 
  def debug(progname = nil, &block)  ; add(DEBUG  , nil, progname, &block);end
  
  #  INFO 情報を出力します。
  # 
  # ==== 詳細
  # ブロックを与えなかった場合は、progname をメッセージとしてログを出力します。
  # ブロックを与えた場合は、ブロックを評価した結果をメッセージとして ログを出力します。
  # 引数とブロックを同時に与えた場合は、progname をプログラム名、ブロックを評価した 結果をメッセージとしてログを出力します。
  # 
  # ==== 引数
  # progname:  ブロックを与えない場合は、メッセージとして文字列または例外オブジェクトを指定します。 ブロックを与えた場合は、プログラム名を文字列として与えます。 
  def info(progname = nil, &block)   ; add(INFO   , nil, progname, &block);end
  
  #  WARN 情報を出力します。
  # 
  # ==== 詳細
  # ブロックを与えなかった場合は、progname をメッセージとしてログを出力します。
  # ブロックを与えた場合は、ブロックを評価した結果をメッセージとして ログを出力します。
  # 引数とブロックを同時に与えた場合は、progname をプログラム名、ブロックを評価した 結果をメッセージとしてログを出力します。
  # 
  # ==== 引数
  # progname:  ブロックを与えない場合は、メッセージとして文字列または例外オブジェクトを指定します。 ブロックを与えた場合は、プログラム名を文字列として与えます。 
  def warn(progname = nil, &block)   ; add(WARN   , nil, progname, &block);end

  #  ERROR 情報を出力します。
  # 
  # ==== 詳細
  # ブロックを与えなかった場合は、progname をメッセージとしてログを出力します。
  # ブロックを与えた場合は、ブロックを評価した結果をメッセージとして ログを出力します。
  # 引数とブロックを同時に与えた場合は、progname をプログラム名、ブロックを評価した 結果をメッセージとしてログを出力します。
  # 
  # ==== 引数
  # progname:  ブロックを与えない場合は、メッセージとして文字列または例外オブジェクトを指定します。 ブロックを与えた場合は、プログラム名を文字列として与えます。 
  def error(progname = nil, &block)  ; add(ERROR  , nil, progname, &block);end
  
  #  FATAL 情報を出力します。
  # 
  # ==== 詳細
  # ブロックを与えなかった場合は、progname をメッセージとしてログを出力します。
  # ブロックを与えた場合は、ブロックを評価した結果をメッセージとして ログを出力します。
  # 引数とブロックを同時に与えた場合は、progname をプログラム名、ブロックを評価した 結果をメッセージとしてログを出力します。
  # 
  # ==== 引数
  # progname:  ブロックを与えない場合は、メッセージとして文字列または例外オブジェクトを指定します。 ブロックを与えた場合は、プログラム名を文字列として与えます。 
  def fatal(progname = nil, &block)  ; add(FATAL  , nil, progname, &block);end
  
  #  UNKNOWN 情報を出力します。
  # 
  # ==== 詳細
  # ブロックを与えなかった場合は、progname をメッセージとしてログを出力します。
  # ブロックを与えた場合は、ブロックを評価した結果をメッセージとして ログを出力します。
  # 引数とブロックを同時に与えた場合は、progname をプログラム名、ブロックを評価した 結果をメッセージとしてログを出力します。
  # 
  # ==== 引数
  # progname:  ブロックを与えない場合は、メッセージとして文字列または例外オブジェクトを指定します。 ブロックを与えた場合は、プログラム名を文字列として与えます。 
  def unknown(progname = nil, &block); add(UNKNOWN, nil, progname, &block);end

  # 与えられたブロック内で一時的にログレベルを変更します。
  # ブロック引数には、ログレベルが変更されたロガーが渡されます。
  # 
  # ==== 引数
  # temporary_level: 一時的なログレベル
  #
  def silence(temporary_level = ERROR)
    yield self.class.new(@progname && @progname.dup, @facility, temporary_level)
  end
end
