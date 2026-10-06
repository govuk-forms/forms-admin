class FeatureService
  class UserRequiredError < StandardError; end
  class GroupRequiredError < StandardError; end
  class OrganisationRequiredError < StandardError; end

  attr_reader :group, :organisation

  class << self
    def enabled?(...)
      FeatureService.new.enabled?(...)
    end
  end

  def initialize(user: nil, group: nil, organisation: nil)
    @user = user
    @group = group
    @organisation = organisation
  end

  def enabled?(feature_name)
    return false if Settings.features.blank?

    segments = feature_name.to_s.split(".")
    feature = Settings.features.dig(*segments)

    return feature unless feature.is_a? Config::Options

    if feature.organisations.present?
      raise UserRequiredError, "Feature #{feature_name} requires user to be provided" if @user.blank?

      if @user.organisation.present?
        organisation_key = @user.organisation.slug.underscore.to_sym
        return feature.organisations[organisation_key] if feature.organisations.key?(organisation_key)
      end
    end

    if feature.enabled_by_group.present? && feature.enabled_by_group
      raise GroupRequiredError, "Feature #{feature_name} requires group to be provided" if group.blank?

      return group.send(:"#{feature_name}_enabled?")
    end

    if feature.enabled_by_organisation.present? && feature.enabled_by_organisation
      raise OrganisationRequiredError, "Feature #{feature_name} requires organisation to be provided" if organisation.blank?

      return organisation.send(:"#{feature_name}_enabled?")
    end

    feature.enabled
  end
end
