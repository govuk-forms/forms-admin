class RemoveDeclarationTextFromForms < ActiveRecord::Migration[8.1]
  def change
    remove_column :form_translations, :declaration_text, :text
    remove_column :forms, :declaration_text, :text
  end
end
