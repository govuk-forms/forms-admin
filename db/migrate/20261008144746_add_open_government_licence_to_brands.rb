class AddOpenGovernmentLicenceToBrands < ActiveRecord::Migration[8.1]
  def change
    add_column :brands, :open_government_licence, :boolean, default: false, null: false
  end
end
