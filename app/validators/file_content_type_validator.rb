class FileContentTypeValidator < ActiveModel::EachValidator
  # ICO magic bytes are too weak for Marcel to identify on their own, so the
  # filename and declared type are needed as fallbacks
  def self.content_type(file)
    Marcel::MimeType.for(file.tempfile, name: file.original_filename, declared_type: file.content_type)
  end

  def validate_each(record, attribute, value)
    return if value.blank?

    content_type = self.class.content_type(value)
    record.errors.add(attribute, :invalid_file_type) unless options.fetch(:in).include?(content_type)
  end
end
