# frozen_string_literal: true

require 'stringio'

class StringResponse
  # Not implementing this interface causes a memory leak.
  # Symptom:
  # uri:classloader:/ruby/slim_helper.rb:25: warning: already initialized constant org.jruby.gen::InterfaceImpl1623561560
  include Java::JakartaServletHttp::HttpServletResponse

  attr_accessor :content_type
  attr_reader :writer

  def initialize
    @string_io = StringIO.new
    @writer = java.io.PrintWriter.new(@string_io.to_output_stream)
  end

  # Implement the Java interface method to return nil/empty to avoid type conflicts
  # This prevents JRuby from trying to auto-implement it with type checking
  def getCharacterEncoding
    nil
  end

  def setCharacterEncoding(encoding)
    # No-op to satisfy interface
  end

  def body
    @writer.flush
    @string_io.string
  end
end
