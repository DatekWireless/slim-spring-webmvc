# frozen_string_literal: true

require 'bigdecimal'

class Java::JavaMath::BigDecimal
  def to_bd
    BigDecimal(toString)
  end

  def to_s
    java.text.NumberFormat.getInstance(Thread.current[:locale]).format(self)
  end
end
