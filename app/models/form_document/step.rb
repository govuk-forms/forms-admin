class FormDocument::Step
  include ActiveModel::API
  include ActiveModel::Attributes

  attr_reader :routing_conditions, :exit_pages

  attribute :id, :string
  attribute :data, DataStructType.new
  attribute :type, :string
  attribute :position, :integer
  attribute :next_step_id, :string

  delegate_missing_to :data

  def initialize(attributes = {})
    @routing_conditions = attributes.fetch("routing_conditions", []).map { |condition| FormDocument::Condition.new(**condition) }
    @exit_pages = attributes.fetch("exit_pages", []).map { |exit_page| FormDocument::ExitPage.new(**exit_page) }
    attributes.slice!(*self.class.attribute_names)
    super
  end

  def is_optional?
    ActiveRecord::Type::Boolean.new.cast(data.is_optional) || false
  end

  def is_repeatable?
    ActiveRecord::Type::Boolean.new.cast(data.is_repeatable) || false
  end
end
