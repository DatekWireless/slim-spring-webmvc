class Java::JavaMath::BigDecimal
  def to_bd
    # BigDecimal(unscaledValue, precision)
    BigDecimal(toString)
  end
end
