# A sample Guardfile
# More info at https://github.com/guard/guard#readme
guard :rubocop, cli: '--auto-correct --display-cop-names --except Lint/Debugger' do
  watch(/.+\.rb$/)
  watch(%r{(?:.+/)?\.rubocop.*\.yml$}) { |m| File.dirname(m[0]) }

  callback(:start_begin) { puts '👮 🚨 👮 🚨 👮 🚨 👮 🚨 👮 ' }
end

guard :rspec, cmd: 'bundle exec rspec', failed_mode: :focus do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb}) { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb') { 'spec' }
end
