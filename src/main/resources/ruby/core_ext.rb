class Object
  def present? = !blank?
  def blank? = false
end

class NilClass
  def blank? = true
end

class String
  def blank? = strip.empty?
end
