module Users
  class FilterInput < BaseInput
    include UsersHelper

    attr_accessor :search, :organisation_id, :role, :has_access

    def has_filters?
      [search, organisation_id, role, has_access].any?(&:present?)
    end

    def access_options
      user_access_options.unshift(OpenStruct.new(label: I18n.t("users.has_access.any")))
    end

    def role_options
      user_role_options.unshift(OpenStruct.new(label: I18n.t("users.roles.all")))
    end
  end
end
