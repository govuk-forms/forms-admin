module WelshTranslationContentId
  def page_content_id(page_id, attribute)
    "page_#{page_id}_#{attribute}"
  end

  def condition_content_id(condition_id, attribute)
    "condition_#{condition_id}_#{attribute}"
  end
end
