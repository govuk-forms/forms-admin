class CreateOrgDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :org_domains do |t|
      t.references :organisation, null: false, foreign_key: true
      t.string :domain, null: false
      t.timestamps
    end

    add_index :org_domains, [:organisation_id, :domain], unique: true, name: "index_org_domains_unique"
    add_index :org_domains, :domain
  end
end
