# In RSpec 3, these symbols will be treated as metadata keys with
# a value of `true`.  To get this behavior now (and prevent this
# warning), you can set a configuration option:

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.run_all_when_everything_filtered = true
end
