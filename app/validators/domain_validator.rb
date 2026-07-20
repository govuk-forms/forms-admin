class DomainValidator < ActiveModel::EachValidator
  REGEX = /\A([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}\Z/i

  def validate_each(record, attribute, value)
    return true if value.blank?

    unless value.match?(/\A[a-z0-9]+([-.]{1}[a-z0-9]+)*\.[a-z]{2,}\z/i)
      record.errors.add(attribute, :invalid_domain)
    end
  end
end
