class MessageSourceAccessor
  def initialize(message_source, locale)
    @message_source = message_source
    @locale = locale
  end

  def [](keys, *args)
    [*keys].each do |key|
      m = @message_source.get_message(key.to_s, args.to_java, nil, @locale)
      return m if m
    end
    "???#{keys}???"
  end
end
