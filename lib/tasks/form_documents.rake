# frozen_string_literal: true

namespace :form_documents do
  desc "Show form document as JSON"
  task :show, %i[form_id ref language] => :environment do |_, args|
    usage_message = "usage: rake form_documents:show[<form_id>, <ref>, <language>]"

    abort usage_message if args[:form_id].blank? || args[:ref].blank?
    language = args[:language].presence || "en"

    begin
      ref = parse_ref(args[:ref])
    rescue ArgumentError
      abort "ref must be version number or one of draft, live or archived"
    end

    abort "language must be en or cy" unless %w[en cy].include?(language)

    form = Form.find(args[:form_id])

    form_document = find_form_document_by_ref(form, ref:, language:)

    abort "#{fmt_form(form)} does not have a #{fmt_ref(ref)} #{language} form document" if form_document.blank?

    puts JSON.pretty_generate(form_document.as_json)
  end
end

def fmt_form(form)
  "form #{form.id} (\"#{form.name}\")"
end

def parse_ref(string)
  case string
  when /\d+/
    string.to_i
  when "draft", "live", "archived"
    string
  else
    raise ArgumentError, "Cannot parse ref '#{string}'"
  end
end

def find_form_document_by_ref(form, ref:, language:)
  case ref
  when "draft"
    form.form_documents.find_by(tag: ref, language:)
  when "live", "archived"
    form_document = FormDocument.latest_live_or_archived(form_id: form.id, language:)
    form_document.tag == ref ? form_document : nil
  when Integer
    form.form_documents.find_by(version: ref, language:)
  end
end

def fmt_ref(ref)
  case ref
  when "draft", "live", "archived"
    ref
  when Integer
    "version #{ref}"
  else
    ref
  end
end
