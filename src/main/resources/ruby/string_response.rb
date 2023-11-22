# frozen_string_literal: true

require 'stringio'

class StringResponse
  include javax.servlet.http.HttpServletResponse

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
