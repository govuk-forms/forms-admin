class ChangeUniqueIndexesOnFormDocuments < ActiveRecord::Migration[8.1]
  def up
    remove_index :form_documents, name: "index_form_documents_on_form_id_tag_and_language"

    # Only one form_document with the same version per language per form
    add_index :form_documents, %i[form_id version language], name: "index_form_documents_on_form_id_version_and_language", unique: true

    # Only one form_document with a null version (the draft form document) per language per form
    add_index :form_documents, %i[form_id language], name: "index_form_documents_only_one_draft_per_language", unique: true, where: "version IS NULL"
  end

  def down
    remove_index :form_documents, name: "index_form_documents_only_one_draft_per_language"

    remove_index :form_documents, name: "index_form_documents_on_form_id_version_and_language"

    add_index :form_documents, %i[form_id tag language], name: "index_form_documents_on_form_id_tag_and_language", unique: true
  end
end
