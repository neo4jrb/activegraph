# This is copied from Rails Active Support since it has been depricated and I still need it

# Taken from: https://raw.github.com/lifo/docrails/dd6c3676af3fa6019c53a59f62c4fd14966be728/activesupport/lib/active_support/core_ext/class/inheritable_attributes.rb

# Changes made:
# - Remove deprecation warnings
# - Ignore if already available from ActiveSupport

# TODO: convert the code to use class_attribute. dnagir failed at it :)



begin
  require 'active_support/core_ext/class/inheritable_attributes'
rescue LoadError
ensure
  # Fallback to internal implementation & override deprecations
  require 'neo4j/core_ext/class/rewrite_inheritable_attributes.rb'
end
