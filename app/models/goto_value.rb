module GotoValue
  DEFAULT_STRING = "default".freeze
  END_OF_FORM_STRING = "end_of_form".freeze
  PAGE_PREFIX = "page_".freeze

  DefaultValue = Data.define do
    def to_s = DEFAULT_STRING
  end

  EndOfFormValue = Data.define do
    def to_s = END_OF_FORM_STRING
  end

  Page = Data.define(:page_id) do
    def to_s = "#{PAGE_PREFIX}#{page_id}"
  end

  def self.from_string(value)
    case value
    when DEFAULT_STRING
      DefaultValue.new
    when END_OF_FORM_STRING
      EndOfFormValue.new
    when ->(v) { v.start_with?(PAGE_PREFIX) }
      Page.new(value.split("_").last.to_i)
    else
      raise ArgumentError, "Unrecognised goto value: #{value.inspect}"
    end
  end
end
