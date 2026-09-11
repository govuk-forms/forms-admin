class StepSummaryCardPresenter
  class << self
    def call(**args)
      new(**args)
    end
  end

  def initialize(step:, steps:, welsh_steps: nil, multiple_branches_enabled: false)
    @step = step
    @steps = steps
    @welsh_steps = welsh_steps
    @multiple_branches_enabled = multiple_branches_enabled
  end

  def build_card
    {
      title: build_title,
      classes: "app-summary-card",
    }
  end

  def build_summary_list
    {
      rows: StepSummaryCardService.call(step: @step, steps: @steps, multiple_branches_enabled: @multiple_branches_enabled).all_options_for_answer_type,
    }
  end

  def build_exit_page_list(exit_page, number)
    {
      rows: [
        { key: { text: I18n.t("step_summary_card.exit_page.heading", exit_page_number: number) }, value: { text: exit_page.heading } },
        { key: { text: I18n.t("step_summary_card.exit_page.content", exit_page_number: number) }, value: { text: exit_page.markdown } },
      ],
    }
  end

  def build_bilingual_exit_page(exit_page, number)
    {
      classes: %w[app-translation-table],
      head: bilingual_table_header,
      rows: welsh_exit_page_rows(exit_page, number),
      first_cell_is_header: true,
    }
  end

  def build_bilingual_table
    {
      classes: %w[app-translation-table],
      head: bilingual_table_header,
      rows: step_summary_table_service.values_with_welsh_content,
      first_cell_is_header: true,
    }
  end

  def build_bilingual_table2
    {
      classes: %w[app-translation-table],
      head: bilingual_table_header,
      rows: step_summary_table_service.values_with_welsh_content2,
      first_cell_is_header: true,
    }
  end

  def build_untranslated_content
    step_summary_table_service.untranslated_content
  end

  def build_route_tables
    return nil if step_summary_table_service.route_content.empty?

    step_summary_table_service.route_content.map do |route|
      if route[:secondary_skip]
        rows =  build_secondary_step_rows(route)
        caption = "Route for any other answer"
      else
        rows = build_primary_route_rows(route)
        caption = "Question #{page_number(@step)}’s route"
      end

      {
        route_table: translation_table_config(caption:, rows:),
        exit_page_table: (build_exit_page_table(route) if route[:exit_page]),
      }
    end
  end

private

  def build_title
    page_number = page_number(@step)
    heading = @step.page_heading
    question = @step.question_text

    # Use the actual heading instead of the question text for the title on file upload type
    title = if @step.answer_type == "file" && heading.present?
              "#{page_number}. #{heading}"
            else
              "#{page_number}. #{question}"
            end

    title += " (optional)" if @step.is_optional? && @step.answer_type != "selection"

    title += "<br><span lang=\"cy\" class=\"govuk-!-font-weight-regular\">#{build_title_cy}</span>" if welsh_step.present?

    ActionController::Base.helpers.sanitize(title)
  end

  def build_title_cy
    page_number = welsh_step.position
    heading = welsh_step.page_heading
    question = welsh_step.question_text

    # Use the actual heading instead of the question text for the title on file upload type
    title = if welsh_step.answer_type == "file" && heading.present?
              "#{page_number}. #{heading}"
            else
              "#{page_number}. #{question}"
            end

    title += " (dewisol)" if welsh_step.is_optional? && welsh_step.answer_type != "selection"

    title
  end

  def page_number(step)
    @steps.find_index(step) + 1
  end

  def welsh_step
    return nil if @welsh_steps.blank?

    @welsh_steps.find { |welsh_step| welsh_step.id == @step.id }
  end

  def welsh_exit_page(exit_page)
    welsh_step.exit_pages.find { |page| page.id == exit_page.id }
  end

  def step_summary_table_service
    StepSummaryTableService.call(step: @step, steps: @steps, welsh_steps: @welsh_steps)
  end

  def translation_table_config(caption: nil, rows: [])
    {
      caption:,
      classes: %w[app-translation-table],
      head: bilingual_table_header,
      rows:,
      first_cell_is_header: true,
    }
  end

  def bilingual_table_header
    [
      { text: nil, classes: "app-translation-table__empty-header-cell" },
      { text: I18n.t("forms.welsh_translation.new.english_header") },
      { text: I18n.t("forms.welsh_translation.new.welsh_header") },
    ]
  end

  def build_secondary_step_rows(route)
    [
      [
        "Continue to",
        route[:check_page],
        route[:check_page_cy],
      ],
      [
        "Then after",
        route[:routing_page],
        route[:routing_page_cy],
      ],
      [
        "skip the person to",
        route[:goto_page],
        route[:goto_page_cy],
      ],
    ]
  end

  def build_primary_route_rows(route)
    [
      [
        "If the answer is",
        route[:answer_value],
        route[:answer_value_cy],
      ],
      [
        "Take the person to",
        route[:goto_page],
        route[:goto_page_cy],
      ],
    ]
  end

  def build_exit_page_table(route)
    rows = [
      [
        "Page title",
        route[:exit_page_heading],
        route[:exit_page_heading_cy],
      ],
      [
        "Page content",
        { text: route[:exit_page_markdown], classes: %w[app-translation-table__markdown-preview] },
        { text: route[:exit_page_markdown_cy], classes: %w[app-translation-table__markdown-preview] },
      ],
    ]

    translation_table_config(caption: "Exit page", rows:)
  end

  def welsh_exit_page_rows(exit_page, number)
    [
      [
        I18n.t("step_summary_card.exit_page.heading", exit_page_number: number),
        exit_page.heading,
        welsh_exit_page(exit_page).heading,
      ],
      [
        I18n.t("step_summary_card.exit_page.content", exit_page_number: number),
        exit_page.markdown,
        welsh_exit_page(exit_page).markdown,
      ],
    ]
  end
end
