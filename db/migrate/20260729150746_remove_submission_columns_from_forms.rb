class RemoveSubmissionColumnsFromForms < ActiveRecord::Migration[8.1]
  def up
    change_table(:forms, bulk: true) do |t|
      t.remove :submission_type
      t.remove :submission_format
      t.remove :send_daily_submission_batch
      t.remove :send_weekly_submission_batch
      t.remove :language
    end
  end

  def down
    change_table(:forms, bulk: true) do |t|
      t.string :submission_type, default: "email", null: false
      t.string :submission_format, default: [], null: false, array: true
      t.boolean :send_daily_submission_batch, default: false
      t.boolean :send_weekly_submission_batch, default: false
      t.string :language, default: "en", null: false
    end
  end
end
