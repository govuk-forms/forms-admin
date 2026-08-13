class AddBrandingAttributesToBrands < ActiveRecord::Migration[8.1]
  def change
    change_table :brands, bulk: true do |t|
      t.string :header_background_colour
      t.string :border_colour
      t.string :logo_alt_text
      t.string :logo_link
      t.string :copyright_holder
    end
  end
end
