class AddLatestFormDocumentIdToForms < ActiveRecord::Migration[8.1]
  def change
    add_reference :forms, :latest_form_document, null: true, foreign_key: { to_table: :form_documents, on_delete: :nullify }
  end
end
