require 'log'

module ClassPatcher
  include Log
  def patch_class_with_module(clazz, patch)
    return if clazz.ancestors.include?(patch)
    LOG.info "Patching class #{clazz.inspect} with module #{patch}"
    clazz.prepend patch
  end
end