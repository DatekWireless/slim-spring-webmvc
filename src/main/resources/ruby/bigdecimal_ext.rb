# frozen_string_literal: true

require 'bigdecimal'

module BigDecimalExt
  def to_s(format = nil)
    if format
      return super(format)
    end
    java.text.NumberFormat.getInstance(Thread.current[:locale]).format(self)
  end

  def to_fs(format = nil)
    to_s(format || 'F')
  end
end
BigDecimal.prepend BigDecimalExt

module FloatExt
  def to_fs(localize = false)
    if localize
      java.text.NumberFormat.getInstance(Thread.current[:locale]).format(self)
    end
    return super()
  end

  def to_s
    to_fs(true)
  end
end
Float.prepend FloatExt

class Java::JavaMath::BigDecimal
  def to_bd
    BigDecimal(toString)
  end

  def to_fs(format = nil)
    to_bd.to_fs(format || 'F')
  end

  def to_s
    java.text.NumberFormat.getInstance(Thread.current[:locale]).format(self)
  end
end
