class AddBrandIdToForms < ActiveRecord::Migration[8.1]
  def change
    add_column :forms, :brand_id, :string
  end
end
