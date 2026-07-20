class AddCustomBrandingEnabledToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :custom_branding_enabled, :boolean, default: false
  end
end
