class Reports::AddAnotherAnswerUsageService
  def add_another_answer_forms
    forms = Form.includes(:pages)
                .where(pages: { is_repeatable: true })
                .map(&method(:form_data))

    OpenStruct.new(forms:, count: forms.length)
  end

private

  def form_data(form)
    OpenStruct.new(
      form_id: form.id,
      name: form.name,
      state: form.state,
      repeatable_pages: form.pages.order(:position).map { |page| OpenStruct.new(page_id: page.id, question_text: page.question_text) if page.is_repeatable }.compact,
    )
  end
end
