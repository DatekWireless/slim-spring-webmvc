class MessageSourceAccessor
  def initialize(message_source, locale)
    @message_source = message_source
    @locale = locale
  end

  def [](key, *args)
    @message_source.get_message(key, args.to_java, "???#{key}???", @locale)
  end
end
