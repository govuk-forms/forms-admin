class Analytics::FormSnapshotService
  attr_reader :snapshot_at

  # snapshot_at is the same on every row in a run, which is how queries tell
  # runs apart
  def initialize(snapshot_at: Time.current.utc)
    @snapshot_at = snapshot_at
  end

  # One row per form, matching the columns of the form_snapshots table. Forms
  # in internal organisations are left out, as they are from the reports pages.
  def rows
    Form.where.not(id: internal_organisation_form_ids).find_each(batch_size: 100).map { |form| row(form) }
  end

private

  def internal_organisation_form_ids
    GroupForm.joins(group: :organisation).where(organisations: { internal: true }).select(:form_id)
  end

  def row(form)
    {
      snapshot_at: snapshot_at.iso8601(3),
      form_id: form.id.to_s,
      organisation_id: form.group&.organisation_id&.to_s,
      state: form.state,
      properties: properties(form),
    }
  end

  # Features describe the version people filling in the form see, so they come
  # from the published document unless the form has never been live
  def properties(form)
    form_document = form.draft? ? form.draft_form_document : form.latest_form_document
    return if form_document.nil?

    # FormDocumentsService.form_documents adds welsh_completed from the form in
    # its query, so do the same here to match the features report
    features = Reports::FormDocumentsService.features(
      form_document.as_json.merge("welsh_completed" => form.welsh_completed),
    )

    # properties is a string column, so the JSON is encoded again inside the
    # record
    features.to_json
  end
end
