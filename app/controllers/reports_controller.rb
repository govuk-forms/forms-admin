class ReportsController < WebController
  before_action :check_user_has_permission
  after_action :verify_authorized

  def index; end

  def features
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    data = Reports::FeatureReportService.new(forms).report
    total_submissions = total_submissions_for_features(tag)

    render template: "reports/features", locals: { tag:, data:, total_submissions: }
  end

  def questions_with_answer_type
    tag = params[:tag]
    answer_type = params.require(:answer_type)
    forms = Reports::FormDocumentsService.form_documents(tag:)
    questions = Reports::FeatureReportService.new(forms).questions_with_answer_type(answer_type)

    if params[:format] == "csv"
      send_data Reports::QuestionsCsvReportService.new(questions).csv,
                type: "text/csv; charset=iso-8859-1",
                disposition: "attachment; filename=#{questions_csv_filename(tag, answer_type)}"
    else
      render template: "reports/questions_with_answer_type", locals: { tag:, answer_type:, questions: }
    end
  end

  def questions_with_add_another_answer
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    questions = Reports::FeatureReportService.new(forms).questions_with_add_another_answer

    questions_feature_report(tag, params[:action], questions)
  end

  def forms_that_are_copies
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    forms = Reports::FeatureReportService.new(forms).forms_that_are_copies

    forms_feature_report(tag, params[:action], forms)
  end

  def forms_with_routes
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    forms = Reports::FeatureReportService.new(forms).forms_with_routes

    forms_feature_report(tag, params[:action], forms, type: :forms_with_routes)
  end

  def forms_with_branch_routes
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    forms = Reports::FeatureReportService.new(forms).forms_with_branch_routes

    forms_feature_report(tag, params[:action], forms, type: :forms_with_routes)
  end

  def forms_with_payments
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    forms = Reports::FeatureReportService.new(forms).forms_with_payments

    forms_feature_report(tag, params[:action], forms)
  end

  def forms_with_exit_pages
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    forms = Reports::FeatureReportService.new(forms).forms_with_exit_pages

    forms_feature_report(tag, params[:action], forms)
  end

  def forms_with_csv_submission_email_attachments
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    forms = Reports::FeatureReportService.new(forms).forms_with_csv_submission_email_attachments

    forms_feature_report(tag, params[:action], forms)
  end

  def forms_with_json_submission_email_attachments
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    forms = Reports::FeatureReportService.new(forms).forms_with_json_submission_email_attachments

    forms_feature_report(tag, params[:action], forms)
  end

  def forms_with_daily_submission_csv
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    forms = Reports::FeatureReportService.new(forms).forms_with_daily_submission_csv

    forms_feature_report(tag, params[:action], forms)
  end

  def forms_with_weekly_submission_csv
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    forms = Reports::FeatureReportService.new(forms).forms_with_weekly_submission_csv

    forms_feature_report(tag, params[:action], forms)
  end

  def forms_with_s3_submissions
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    forms = Reports::FeatureReportService.new(forms).forms_with_s3_submissions

    forms_feature_report(tag, params[:action], forms)
  end

  def forms_with_welsh_translation
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    forms = Reports::FeatureReportService.new(forms).forms_with_welsh_translation

    forms_feature_report(tag, params[:action], forms)
  end

  def users
    data = Reports::UsersReportService.new.user_data

    render locals: { data: }
  end

  def add_another_answer
    data = Reports::AddAnotherAnswerUsageService.new.add_another_answer_forms

    render template: "reports/add_another_answer", locals: { data: }
  end

  def last_signed_in_at; end

  def selection_questions_summary
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    data = Reports::SelectionQuestionService.new(forms).statistics

    render template: "reports/selection_questions_summary", locals: { tag:, data: }
  end

  def selection_questions_with_autocomplete
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    questions = Reports::FeatureReportService.new(forms).selection_questions_with_autocomplete

    questions_feature_report(tag, params[:action], questions, type: :selection_questions)
  end

  def selection_questions_with_radios
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    questions = Reports::FeatureReportService.new(forms).selection_questions_with_radios

    questions_feature_report(tag, params[:action], questions, type: :selection_questions)
  end

  def selection_questions_with_checkboxes
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    questions = Reports::FeatureReportService.new(forms).selection_questions_with_checkboxes

    questions_feature_report(tag, params[:action], questions, type: :selection_questions)
  end

  def selection_questions_with_none_of_the_above
    tag = params[:tag]
    forms = Reports::FormDocumentsService.form_documents(tag:)
    questions = Reports::FeatureReportService.new(forms).selection_questions_with_none_of_the_above

    questions_feature_report(tag, params[:action], questions, type: :selection_questions_with_none_of_the_above)
  end

  def csv_downloads; end

  def live_forms_csv
    forms = Reports::FormDocumentsService.form_documents(tag: "live-or-archived")

    send_data Reports::FormsCsvReportService.new(forms).csv,
              type: "text/csv; charset=iso-8859-1",
              disposition: "attachment; filename=#{csv_filename('live_forms_report')}"
  end

  def live_questions_csv
    forms = Reports::FormDocumentsService.form_documents(tag: "live-or-archived")
    questions = Reports::FeatureReportService.new(forms).questions

    send_data Reports::QuestionsCsvReportService.new(questions).csv,
              type: "text/csv; charset=iso-8859-1",
              disposition: "attachment; filename=#{csv_filename('live_questions_report')}"
  end

  def contact_for_research
    data = Reports::ContactForResearchService.new.contact_for_research_data

    render locals: { data: }
  end

  def total_submissions
    data = Reports::TotalSubmissionsCloudWatchService.new.submissions_data
    render locals: { data: }
  end

private

  def questions_feature_report(tag, report, questions, type: :questions)
    if params[:format] == "csv"
      send_data Reports::QuestionsCsvReportService.new(questions).csv,
                type: "text/csv; charset=iso-8859-1",
                disposition: "attachment; filename=#{csv_filename("#{tag}_#{report}_report")}"
    else
      render template: "reports/feature_report", locals: { tag:, report:, records: questions, type: }
    end
  end

  def forms_feature_report(tag, report, forms, type: :forms)
    if params[:format] == "csv"
      send_data Reports::FormsCsvReportService.new(forms).csv,
                type: "text/csv; charset=iso-8859-1",
                disposition: "attachment; filename=#{csv_filename("#{tag}_#{report}_report")}"
    else
      render template: "reports/feature_report", locals: { tag:, report:, records: forms, type: }
    end
  end

  def total_submissions_for_features(tag)
    return nil unless tag == "live-or-archived"

    submissions_data = Reports::TotalSubmissionsCloudWatchService.new.submissions_data
    {
      total: submissions_data&.dig(:all_time, :total),
      available: !submissions_data.nil?,
    }
  end

  def check_user_has_permission
    authorize :report, :can_view_reports?
  end

  def questions_csv_filename(tag, answer_type)
    base_name = "#{tag}_questions_report"
    base_name += "_#{answer_type}_answer_type" if answer_type.present?
    csv_filename(base_name)
  end

  def csv_filename(base_name)
    "#{base_name}-#{Time.zone.now}.csv"
  end
end
