class FormCopyService
  include LoggingHelper

  DONT_COPY = %i[created_at
                 updated_at
                 first_made_live_at
                 submission_email
                 s3_bucket_aws_account_id
                 s3_bucket_name
                 s3_bucket_region].freeze
  TO_COPY = Form::FORM_DOCUMENT_ATTRIBUTES - DONT_COPY

  def initialize(form, logged_in_user)
    @form = form
    @copied_form = Form.new
    @logged_in_user = logged_in_user
    @exit_page_id_mapping = {}
    @exit_pages_by_condition_id = {}
  end

  def copy(tag: "draft")
    # Copy the main form structure from English FormDocument first
    form_doc = tag == "draft" ? @form.draft_form_document : @form.latest_form_document
    return false if form_doc.blank?

    content = form_doc.content

    ActiveRecord::Base.transaction do
      copy_attributes(content)
      prepend_name_for_language(:en)

      copy_pages(content["steps"])
      copy_exit_pages(content["steps"])
      copy_routing_conditions(content["steps"])

      @copied_form.copied_from_id = @form.id
      @copied_form.creator_id = @logged_in_user.id
      @copied_form.save!

      copy_group

      # Copy Welsh translations if available
      if content&.[]("available_languages")&.include?("cy")
        copy_welsh_translations(tag:, version: form_doc.version)
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to copy form #{@form.id}: #{e.message}")
      raise
    end

    log_form_copied(original_form_id: @form.id, copied_form_id: @copied_form.id, creator_id: @logged_in_user.id)

    @copied_form.reload
    @copied_form
  end

private

  def attributes_to_copy
    TO_COPY.map(&:to_s)
  end

  def copy_attributes(content)
    @copied_form.assign_attributes(content.slice(*attributes_to_copy))
  end

  def copy_pages(steps)
    return if steps.blank?

    steps.each do |step|
      page = @copied_form.pages.build
      copy_page_attributes(page, step)
      page.save!
    end
  end

  def copy_exit_pages(steps)
    return if steps.blank?

    steps.each_with_index do |step, index|
      page = @copied_form.pages[index]

      (step["exit_pages"] || []).each do |ep_data|
        exit_page = page.exit_pages.build(
          heading: ep_data["heading"],
          markdown: ep_data["markdown"],
        )
        exit_page.save!
        @exit_page_id_mapping[ep_data["id"]] = exit_page
      end
    end
  end

  def copy_page_attributes(page, step)
    data = step["data"]
    page.assign_attributes(
      position: step["position"],
      question_text: data["question_text"],
      hint_text: data["hint_text"],
      answer_type: data["answer_type"],
      is_optional: data["is_optional"],
      answer_settings: data["answer_settings"],
      page_heading: data["page_heading"],
      guidance_markdown: data["guidance_markdown"],
      is_repeatable: data["is_repeatable"],
    )
  end

  def prepend_name_for_language(language)
    if language == :en
      @copied_form.name = "Copy of #{@form.name}"
    elsif language == :cy
      @copied_form.name_cy = "Copy of #{@form.name_cy}" if @form.name_cy.present?
    end
  end

  def copy_welsh_translations(tag:, version:)
    # Get the Welsh version corresponding to the English version
    welsh_doc = FormDocument.find_by(form_id: @form.id, tag:, version:, language: :cy)
    return unless welsh_doc

    welsh_content = welsh_doc.content

    # Copy Welsh translations from FormDocument content
    Mobility.with_locale(:cy) do
      welsh_content.slice(*Form.mobility_attributes).each do |key, value|
        @copied_form.send("#{key}=", value) if value.present?
      end
      prepend_name_for_language(:cy)

      # Copy Welsh page translations
      copy_welsh_page_translations(welsh_content["steps"])

      @copied_form.save!
    end
  end

  def copy_routing_conditions(steps)
    return if steps.blank?

    # Build a mapping from old page IDs to new page objects
    page_id_mapping = steps.each_with_index.to_h { |step, index| [step["id"], @copied_form.pages[index]] }

    # Extract all conditions from all steps and copy them
    all_conditions_data = steps.flat_map { |step| step["routing_conditions"] || [] }
    all_conditions_data.each do |condition_data|
      copy_condition(condition_data, page_id_mapping)
    end
  end

  def copy_condition(condition_data, page_id_mapping)
    routing_page = page_id_mapping[condition_data["routing_page_id"]]

    Condition.create!(
      routing_page:,
      check_page: page_id_mapping[condition_data["check_page_id"]],
      goto_page: page_id_mapping[condition_data["goto_page_id"]],
      answer_value: condition_data["answer_value"],
      skip_to_end: condition_data["skip_to_end"] || false,
      exit_page: exit_page_for_condition(condition_data, routing_page),
    )
  end

  def exit_page_for_condition(condition_data, routing_page)
    @exit_page_id_mapping[condition_data["exit_page_id"]] || copy_exit_page_from_condition(condition_data, routing_page)
  end

  # Older form documents only have the exit page content on the condition,
  # so there is no entry in the step's exit pages to copy it from.
  def copy_exit_page_from_condition(condition_data, routing_page)
    heading = condition_data["exit_page_heading"]
    markdown = condition_data["exit_page_markdown"]
    return if heading.blank? || markdown.blank?

    exit_page = routing_page.exit_pages.create!(heading:, markdown:)
    @exit_pages_by_condition_id[condition_data["id"]] = exit_page
    exit_page
  end

  def copy_group
    GroupForm.create(group_id: @form.group.id, form_id: @copied_form.id)
  end

  def copy_welsh_page_translations(welsh_steps)
    return if welsh_steps.blank?

    welsh_steps.each_with_index do |step, index|
      page = @copied_form.pages[index]
      next unless page

      data = step["data"]
      # Copy Welsh translatable fields for the page
      # We need to reload to ensure Mobility has the right locale context
      page.reload
      Page.mobility_attributes.each do |attr|
        page.send("#{attr}=", data[attr]) if data[attr].present?
      end
      copy_welsh_exit_pages(step)
      page.save!(validate: false)
    end
  end

  def copy_welsh_exit_pages(step)
    (step["exit_pages"] || []).each do |ep_data|
      copy_welsh_exit_page(@exit_page_id_mapping[ep_data["id"]], heading: ep_data["heading"], markdown: ep_data["markdown"])
    end

    # Exit pages created from the content on a condition in an older form
    # document get their Welsh from the same condition in the Welsh document.
    (step["routing_conditions"] || []).each do |condition_data|
      copy_welsh_exit_page(@exit_pages_by_condition_id[condition_data["id"]], heading: condition_data["exit_page_heading"], markdown: condition_data["exit_page_markdown"])
    end
  end

  def copy_welsh_exit_page(exit_page, heading:, markdown:)
    return unless exit_page

    exit_page.heading = heading if heading.present?
    exit_page.markdown = markdown if markdown.present?
    exit_page.save!
  end
end
