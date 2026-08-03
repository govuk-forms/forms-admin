class AllowedEmailDomainValidator < ActiveModel::EachValidator
  ALLOWED_SUBDOMAIN_REGEXES = [/\.gov\.uk\z/i,
                               /\.gov\.scot\z/i,
                               /\.gov\.wales\z/i,
                               /\.mod\.uk\z/i].freeze

  def validate_each(record, attribute, value)
    if value.present?

      return if ALLOWED_SUBDOMAIN_REGEXES.any? { it.match?(value) }

      domain = value.split("@").last
      organisation_domains = record.try(:form)&.group&.organisation&.organisation_domains
      return if organisation_domains&.any? { |organisation_domain| domain == organisation_domain.domain }
    end

    record.errors.add(attribute, :non_government_email)
  end
end
