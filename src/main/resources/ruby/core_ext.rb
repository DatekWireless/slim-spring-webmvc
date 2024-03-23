class Object
  def present? = !blank?

  def blank? = false

  def try(method, *args)
    return nil unless self.respond_to?(method)
    send(method, *args)
  end
end

class NilClass
  def blank? = true

  def try(*) = nil
end

class FalseClass
  def blank? = true
end

class String
  def blank? = strip.empty?
end
