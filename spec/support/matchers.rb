# :nocov:
RSpec::Matchers.define :have_error_on do |*attributes|
  @message = nil
  all_attributes = [attributes]

  chain :or do |*or_attributes|
    all_attributes << or_attributes
  end

  match do |model|
    model.valid?
    @has_errors = all_attributes.detect { |attribute| model.errors[attribute[0]].present? }
    if @message
      !!@has_errors && model.errors[@has_errors[0]].include?(@has_errors[1])
    else
      !!@has_errors
    end
  end
end
# :nocov:
