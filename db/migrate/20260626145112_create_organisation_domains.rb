class CreateOrganisationDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :organisation_domains do |t|
      t.references :organisation, null: false, foreign_key: true
      t.string :domain, null: false
      t.timestamps
    end

    add_index :organisation_domains, %i[organisation_id domain], unique: true, name: "index_organisation_domains_unique"
    add_index :organisation_domains, :domain
  end
end
