module Organisations
  class FilterInput < BaseInput
    attr_accessor :name, :agreement_type, :sort

    def has_filters?
      [name, agreement_type].any?(&:present?)
    end

    def sort_options
      [
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.name"), value: "name"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.users"), value: "users"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.live_forms"), value: "live_forms"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.draft_forms"), value: "draft_forms"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.agreement_date"), value: "agreement_date"),
      ]
    end

    def agreement_type_options
      [
        OpenStruct.new(label: I18n.t("organisations.index.filter.agreement_type.any")),
        OpenStruct.new(label: I18n.t("mou_signatures.index.agreement_type.crown"), value: "crown"),
        OpenStruct.new(label: I18n.t("mou_signatures.index.agreement_type.non_crown"), value: "non_crown"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.agreement_type.signed"), value: "signed"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.agreement_type.none"), value: "none"),
      ]
    end
  end
end
