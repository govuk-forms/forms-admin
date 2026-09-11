class AddSaveAndReturnToForms < ActiveRecord::Migration[8.1]
  def change
    add_column :forms, :save_and_return, :string, null: false, default: "disabled"
  end
end
