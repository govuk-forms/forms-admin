module ConditionMethods
  def is_exit_page?
    !exit_page_markdown.nil? || try(:exit_page_id).present?
  end

  alias_method :exit_page?, :is_exit_page?

  def secondary_skip?
    answer_value.blank? && check_page_id != routing_page_id
  end
end
