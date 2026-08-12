namespace :data_migrations do
  desc "backfill version for existing live and archived form documents"
  task set_version_on_form_documents: :environment do
    FormDocument.where(tag: %i[live archived]).find_each do |form_document|
      form_document.update!(version: 1) if form_document.version.nil?
      form_document.form.update!(latest_form_document: form_document) if form_document.language == "en"
    end
  end
end
