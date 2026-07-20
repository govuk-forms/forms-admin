class CreateOrganisationBrands < ActiveRecord::Migration[8.1]
  def change
    create_table :organisation_brands do |t|
      t.references :organisation, null: false, foreign_key: true
      t.references :brand, null: false, foreign_key: true
      t.timestamps
    end

    add_index :organisation_brands, %i[organisation_id brand_id], unique: true, name: "index_organisation_brands_unique"
  end
end
