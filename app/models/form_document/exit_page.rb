class FormDocument::ExitPage
  include ActiveModel::API
  include ActiveModel::Attributes

  attribute :id, :integer
  attribute :created_at, :datetime
  attribute :updated_at, :datetime
  attribute :question_page_id, :string
  attribute :heading, :string
  attribute :markdown, :string

  def initialize(attributes = {})
    attributes.slice!(*self.class.attribute_names)
    super
  end
end
