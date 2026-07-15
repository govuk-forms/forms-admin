class AddDefaultBrandToOrganisations < ActiveRecord::Migration[8.1]
  def change
    add_reference :organisations, :default_brand, null: true, foreign_key: { to_table: :brands }
  end
end
