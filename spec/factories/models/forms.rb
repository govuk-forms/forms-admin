FactoryBot.define do
  factory :form, class: "Form" do
    sequence(:name) { |n| "Form #{n}" }
    submission_email { Faker::Internet.email(domain: "example.gov.uk") }
    submission_type { "email" }
    submission_format { [] }
    privacy_policy_url { Faker::Internet.url(host: "gov.uk") }
    support_email { nil }
    support_phone { nil }
    support_url { nil }
    support_url_text { nil }
    what_happens_next_markdown { nil }
    declaration_markdown { nil }
    question_section_completed { false }
    declaration_section_completed { false }
    share_preview_completed { false }
    creator_id { nil }
    state { :draft }
    payment_url { nil }
    external_id { nil }
    send_daily_submission_batch { false }
    send_weekly_submission_batch { false }

    trait :with_group do
      transient do
        group { nil }
      end

      after(:build) do |form, evaluator|
        g = evaluator.group || FactoryBot.create(:group)
        form.instance_variable_set(:@associated_group, g)
        form.define_singleton_method(:group) { g }
      end

      after(:create) do |form, _evaluator|
        g = form.instance_variable_get(:@associated_group)
        GroupForm.create!(form_id: form.id, group_id: g.id) unless GroupForm.exists?(form_id: form.id, group_id: g.id)
      end
    end

    trait :new_form do
      submission_email { "" }
      privacy_policy_url { "" }
      pages { [] }
      state { :draft }
    end

    trait :with_id do
      sequence(:id) { |n| n }
    end

    trait :with_pages do
      transient do
        pages_count { 5 }
      end

      pages do
        Array.new(pages_count) { association(:page) }
      end

      after(:build) do |form|
        link_pages_list(form.pages) if form.pages.present?
        add_welsh_translations_to_pages(form.pages) if form.available_languages.include?("cy")
      end

      question_section_completed { true }
    end

    trait :with_text_page do
      pages do
        Array.new(1) { association(:page, answer_type: "text", answer_settings: { input_type: %w[single_line long_text].sample }) }
      end

      question_section_completed { true }
    end

    trait :ready_for_live do
      with_pages
      support_email { Faker::Internet.email(domain: "example.gov.uk") }
      what_happens_next_markdown { "We usually respond to applications within 10 working days." }
      question_section_completed { true }
      declaration_section_completed { true }
      share_preview_completed { true }
    end

    trait :with_submission_email do
      association :form_submission_email
    end

    trait :live do
      ready_for_live
      state { :live }
      first_made_live_at { Time.zone.now }
      after(:create) do |form|
        form.available_languages.each do |language|
          Mobility.with_locale(language) do
            FormDocument.create(form:, tag: "live", content: form.as_form_document(live_at: form.updated_at), language:)
          end
        end
      end
    end

    trait :live_with_draft do
      live
      state { :live_with_draft }
    end

    trait :archived do
      ready_for_live
      state { :archived }
      first_made_live_at { Time.zone.now }
      after(:create) do |form|
        form.available_languages.each do |language|
          Mobility.with_locale(language) do
            FormDocument.create(form:, tag: "archived", content: form.as_form_document(live_at: form.updated_at), language:)
          end
        end
      end
    end

    trait :archived_with_draft do
      archived
      state { :archived_with_draft }
    end

    trait :with_support do
      support_email { Faker::Internet.email(domain: "example.gov.uk") }
      support_phone { Faker::Lorem.paragraph(sentence_count: 2, supplemental: true, random_sentences_to_add: 4) }
      support_url { Faker::Internet.url(host: "gov.uk") }
      support_url_text { Faker::Lorem.sentence(word_count: 1, random_words_to_add: 4) }
    end

    trait :ready_for_routing do
      transient do
        pages_count { 5 }
      end

      pages do
        Array.new(pages_count) { association(:page, :with_selection_settings) }
      end

      after(:build) do |form|
        link_pages_list(form.pages) if form.pages.present?
      end
    end

    trait :missing_pages do
      ready_for_live
      question_section_completed { false }
    end

    trait :with_welsh_translation do
      available_languages { %w[en cy] }
      welsh_completed { true }

      name_cy { name.prepend("Welsh ") }
      privacy_policy_url_cy { "#{privacy_policy_url}/cy" }
      support_email_cy { support_email }
      what_happens_next_markdown_cy { "Fel arfer, rydym yn ymateb i geisiadau o fewn 10 diwrnod gwaith." }
    end
  end
end

def link_pages_list(pages)
  pages.to_enum.with_index(1).each do |page, index|
    page.position = index
  end

  pages
end

def add_welsh_translations_to_pages(pages)
  pages.each do |page|
    if page.question_text_cy.blank?
      page.question_text_cy = "Welsh #{page.question_text}"
    end
  end

  pages
end
