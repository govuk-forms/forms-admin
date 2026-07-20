class CreateBrands < ActiveRecord::Migration[8.1]
  def change
    create_table :brands do |t|
      t.string :slug, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :brands, :slug, unique: true
  end
end
