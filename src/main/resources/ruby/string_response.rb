# frozen_string_literal: true

require 'stringio'

class StringResponse
  # Not implementing this interface causes a memory leak.
  # Symptom:
  # uri:classloader:/ruby/slim_helper.rb:25: warning: already initialized constant org.jruby.gen::InterfaceImpl1623561560
  include Java::JakartaServletHttp::HttpServletResponse

  attr_accessor :character_encoding, :content_type
  attr_reader :writer

  def initialize(character_encoding)
    @character_encoding = character_encoding
    @string_io = StringIO.new
    @writer = java.io.PrintWriter.new(@string_io.to_output_stream)
  end

  def body
    @writer.flush
    @string_io.string
  end
end
