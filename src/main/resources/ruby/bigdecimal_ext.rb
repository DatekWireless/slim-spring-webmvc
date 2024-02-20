# frozen_string_literal: true

require 'bigdecimal'

class BigDecimal
  alias :to_fs :to_s
end

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
