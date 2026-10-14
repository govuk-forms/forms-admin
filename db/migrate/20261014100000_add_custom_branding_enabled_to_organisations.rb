class AddCustomBrandingEnabledToOrganisations < ActiveRecord::Migration[8.1]
  def up
    add_column :organisations, :custom_branding_enabled, :boolean, default: false

    # Custom branding was previously turned on per group. Turn it on for any
    # organisation that has a group with it on, so no one loses access.
    execute <<~SQL
      UPDATE organisations SET custom_branding_enabled = TRUE
      WHERE id IN (SELECT organisation_id FROM groups WHERE custom_branding_enabled = TRUE)
    SQL
  end

  def down
    remove_column :organisations, :custom_branding_enabled
  end
end
