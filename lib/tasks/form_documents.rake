# frozen_string_literal: true

namespace :form_documents do
  desc "Show form document as JSON"
  task :show, %i[form_id tag language] => :environment do |_, args|
    usage_message = "usage: rake form_documents:show[<form_id>, <tag>, <language>]"

    abort usage_message if args[:form_id].blank? || args[:tag].blank?
    language = args[:language].presence || "en"

    abort "tag must be one of draft, live or archived" unless %w[draft live archived].include?(args[:tag])
    abort "language must be en or cy" unless %w[en cy].include?(language)

    form = Form.find(args[:form_id])

    form_document = form.form_documents.find_by(tag: args[:tag], language:)
    abort "#{fmt_form(form)} does not have a #{args[:tag]} #{language} form document" if form_document.blank?

    puts JSON.pretty_generate(form_document.as_json)
  end
end

def fmt_form(form)
  "form #{form.id} (\"#{form.name}\")"
end
