# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_24_143146) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "condition_translations", force: :cascade do |t|
    t.bigint "condition_id", null: false
    t.datetime "created_at", null: false
    t.text "exit_page_heading"
    t.text "exit_page_markdown"
    t.string "locale", null: false
    t.datetime "updated_at", null: false
    t.index ["condition_id", "locale"], name: "index_condition_translations_on_condition_id_and_locale", unique: true
    t.index ["locale"], name: "index_condition_translations_on_locale"
  end

  create_table "conditions", force: :cascade do |t|
    t.string "answer_value"
    t.bigint "check_page_id", comment: "The question page this condition looks at to compare answers"
    t.datetime "created_at", null: false
    t.text "exit_page_heading", comment: "Text for the heading of the exit page"
    t.text "exit_page_markdown", comment: "When not nil this condition should be treated as an exit page. When set it contains the markdown for the body of the exit page"
    t.bigint "goto_page_id", comment: "The question page which this conditions will skip forwards to"
    t.bigint "routing_page_id", comment: "The question page at which this conditional route takes place"
    t.boolean "skip_to_end", default: false
    t.datetime "updated_at", null: false
    t.index ["check_page_id"], name: "index_conditions_on_check_page_id"
    t.index ["goto_page_id"], name: "index_conditions_on_goto_page_id"
    t.index ["routing_page_id"], name: "index_conditions_on_routing_page_id"
  end

  create_table "create_form_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "dedup_version"
    t.bigint "form_id"
    t.string "form_name", null: false
    t.bigint "group_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["group_id", "form_name", "dedup_version"], name: "idx_on_group_id_form_name_dedup_version_9b12b4ae60", unique: true
    t.index ["group_id"], name: "index_create_form_events_on_group_id"
    t.index ["user_id"], name: "index_create_form_events_on_user_id"
  end

  create_table "draft_questions", force: :cascade do |t|
    t.jsonb "answer_settings", default: {}
    t.text "answer_type"
    t.datetime "created_at", null: false
    t.integer "form_id"
    t.text "guidance_markdown"
    t.text "hint_text"
    t.boolean "is_optional"
    t.boolean "is_repeatable"
    t.text "page_heading"
    t.integer "page_id"
    t.text "question_text"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["form_id"], name: "index_draft_questions_on_form_id"
    t.index ["user_id"], name: "index_draft_questions_on_user_id"
  end

  create_table "form_documents", force: :cascade do |t|
    t.jsonb "content", comment: "The JSON which describes the form"
    t.datetime "created_at", null: false
    t.bigint "form_id", comment: "The form this document belongs to"
    t.string "language", default: "en", null: false
    t.text "tag", null: false, comment: "The tag for the form, for example: 'live' or 'draft'"
    t.datetime "updated_at", null: false
    t.index ["form_id", "tag", "language"], name: "index_form_documents_on_form_id_tag_and_language", unique: true
    t.index ["form_id"], name: "index_form_documents_on_form_id"
  end

  create_table "form_submission_emails", force: :cascade do |t|
    t.string "confirmation_code"
    t.datetime "created_at", null: false
    t.string "created_by_email"
    t.string "created_by_name"
    t.integer "form_id"
    t.string "temporary_submission_email"
    t.datetime "updated_at", null: false
    t.string "updated_by_email"
    t.string "updated_by_name"
    t.index ["form_id"], name: "index_form_submission_emails_on_form_id"
  end

  create_table "form_translations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "declaration_markdown"
    t.text "declaration_text"
    t.bigint "form_id", null: false
    t.string "locale", null: false
    t.text "name"
    t.string "payment_url"
    t.text "privacy_policy_url"
    t.text "support_email"
    t.text "support_phone"
    t.text "support_url"
    t.text "support_url_text"
    t.datetime "updated_at", null: false
    t.text "what_happens_next_markdown"
    t.index ["form_id", "locale"], name: "index_form_translations_on_form_id_and_locale", unique: true
    t.index ["locale"], name: "index_form_translations_on_locale"
  end

  create_table "forms", force: :cascade do |t|
    t.text "available_languages", default: ["en"], null: false, array: true
    t.integer "copied_from_id"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "declaration_markdown"
    t.boolean "declaration_section_completed", default: false
    t.text "declaration_text"
    t.string "external_id"
    t.datetime "first_made_live_at"
    t.text "form_slug"
    t.string "language", default: "en", null: false
    t.text "name"
    t.string "payment_url"
    t.text "privacy_policy_url"
    t.boolean "question_section_completed", default: false
    t.string "s3_bucket_aws_account_id"
    t.string "s3_bucket_name"
    t.string "s3_bucket_region"
    t.boolean "send_daily_submission_batch", default: false
    t.boolean "send_weekly_submission_batch", default: false
    t.boolean "share_preview_completed", default: false, null: false
    t.string "state"
    t.text "submission_email"
    t.string "submission_format", default: [], null: false, array: true
    t.string "submission_type", default: "email", null: false
    t.text "support_email"
    t.text "support_phone"
    t.text "support_url"
    t.text "support_url_text"
    t.datetime "updated_at", null: false
    t.boolean "welsh_completed", default: false
    t.text "what_happens_next_markdown"
    t.index ["external_id"], name: "index_forms_on_external_id", unique: true
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "external_id", null: false
    t.boolean "multiple_branches_enabled", default: false
    t.string "name"
    t.bigint "organisation_id"
    t.string "status", default: "trial"
    t.datetime "updated_at", null: false
    t.bigint "upgrade_requester_id"
    t.index ["creator_id"], name: "index_groups_on_creator_id"
    t.index ["external_id"], name: "index_groups_on_external_id", unique: true
    t.index ["name", "organisation_id"], name: "index_groups_on_name_and_organisation_id", unique: true
    t.index ["organisation_id"], name: "index_groups_on_organisation_id"
    t.index ["upgrade_requester_id"], name: "index_groups_on_upgrade_requester_id"
  end

  create_table "groups_form_ids", id: false, force: :cascade do |t|
    t.bigint "form_id", null: false
    t.bigint "group_id", null: false
    t.index ["form_id"], name: "index_groups_form_ids_on_form_id", unique: true
    t.index ["group_id"], name: "index_groups_form_ids_on_group_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "added_by_id", null: false, comment: "The user who created the membership"
    t.datetime "created_at", null: false
    t.bigint "group_id", null: false, comment: "The group that the user is a member of"
    t.string "role", default: "editor"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false, comment: "The user who is a member of the group"
    t.index ["added_by_id"], name: "index_memberships_on_added_by_id"
    t.index ["user_id", "group_id"], name: "index_memberships_on_user_id_and_group_id", unique: true, comment: "Ensure that a user can only be a member of a group once"
  end

  create_table "mou_signatures", comment: "User signatures of a memorandum of understanding (MOU) for an organisation", force: :cascade do |t|
    t.string "agreement_type", null: false
    t.datetime "created_at", null: false
    t.bigint "organisation_id", comment: "Organisation which user signed MOU on behalf of, or null"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false, comment: "User who signed MOU"
    t.index ["organisation_id"], name: "index_mou_signatures_on_organisation_id"
    t.index ["user_id", "organisation_id"], name: "index_mou_signatures_on_user_id_and_organisation_id", unique: true, comment: "Users can only sign an MOU for an Organisation once"
    t.index ["user_id"], name: "index_mou_signatures_on_user_id"
    t.index ["user_id"], name: "index_mou_signatures_on_user_id_unique_without_organisation_id", unique: true, where: "(organisation_id IS NULL)", comment: "Users can only sign a single MOU without an organisation"
  end

  create_table "organisations", force: :cascade do |t|
    t.string "abbreviation"
    t.boolean "closed", default: false
    t.datetime "created_at", null: false
    t.string "govuk_content_id"
    t.boolean "internal", default: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["govuk_content_id"], name: "index_organisations_on_govuk_content_id", unique: true
    t.index ["slug"], name: "index_organisations_on_slug", unique: true
  end

  create_table "page_translations", force: :cascade do |t|
    t.jsonb "answer_settings"
    t.datetime "created_at", null: false
    t.text "guidance_markdown"
    t.text "hint_text"
    t.string "locale", null: false
    t.text "page_heading"
    t.bigint "page_id", null: false
    t.text "question_text"
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_page_translations_on_locale"
    t.index ["page_id", "locale"], name: "index_page_translations_on_page_id_and_locale", unique: true
  end

  create_table "pages", force: :cascade do |t|
    t.jsonb "answer_settings"
    t.text "answer_type"
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.bigint "form_id"
    t.text "guidance_markdown"
    t.text "hint_text"
    t.boolean "is_optional", null: false
    t.boolean "is_repeatable", default: false, null: false
    t.text "page_heading"
    t.integer "position"
    t.text "question_text"
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_pages_on_external_id", unique: true
    t.index ["form_id"], name: "index_pages_on_form_id"
  end

  create_table "schema_info", id: false, force: :cascade do |t|
    t.integer "version", default: 0, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "app_name"
    t.datetime "created_at", null: false
    t.boolean "disabled", default: false
    t.string "email"
    t.boolean "has_access", default: true
    t.datetime "last_signed_in_at"
    t.string "name"
    t.string "organisation_content_id"
    t.bigint "organisation_id"
    t.string "organisation_slug"
    t.text "permissions"
    t.string "provider"
    t.boolean "remotely_signed_out", default: false
    t.string "research_contact_status", default: "to_be_asked"
    t.string "role", default: "standard"
    t.datetime "terms_agreed_at"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.datetime "user_research_opted_in_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.jsonb "object"
    t.jsonb "object_changes"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "condition_translations", "conditions"
  add_foreign_key "create_form_events", "groups", on_delete: :cascade
  add_foreign_key "create_form_events", "users", on_delete: :cascade
  add_foreign_key "draft_questions", "users"
  add_foreign_key "form_documents", "forms"
  add_foreign_key "form_translations", "forms"
  add_foreign_key "groups", "users", column: "creator_id"
  add_foreign_key "groups", "users", column: "upgrade_requester_id"
  add_foreign_key "memberships", "groups"
  add_foreign_key "memberships", "users"
  add_foreign_key "memberships", "users", column: "added_by_id"
  add_foreign_key "mou_signatures", "organisations"
  add_foreign_key "mou_signatures", "users"
  add_foreign_key "page_translations", "pages"
  add_foreign_key "pages", "forms"
  add_foreign_key "users", "organisations"
end
