class AddVersionToFormDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :form_documents, :version, :integer, null: true
  end
end
