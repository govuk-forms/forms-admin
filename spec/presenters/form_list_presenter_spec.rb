require "rails_helper"

describe FormListPresenter do
  let(:presenter) { described_class.call(forms:, group:, can_admin:) }

  let(:creator) { create :user }
  let(:forms) { build_list :form, 5, :with_id, creator_id: creator.id, created_at: "2024-10-08T07:31:15.762Z" }
  let(:group) { create :group }
  let(:can_admin) { false }

  describe "#data" do
    describe "caption" do
      it "returns caption containing group name" do
        expect(presenter.data).to include caption: I18n.t("groups.form_table_caption", group_name: group.name)
      end
    end

    describe "head" do
      it "contains a 'Name', `Created by` and 'Status' column heading" do
        expect(presenter.data[:head]).to eq([I18n.t("home.form_name_heading"),
                                             { text: I18n.t("home.created_by") },
                                             { text: I18n.t("home.form_status_heading"), numeric: true }])
      end

      context "when user is org admin" do
        let(:can_admin) { true }

        it "contains an additional 'Actions' column heading" do
          expect(presenter.data[:head]).to eq([I18n.t("home.form_name_heading"),
                                               { text: I18n.t("home.created_by") },
                                               { text: I18n.t("home.form_status_heading"), numeric: true },
                                               { text: I18n.t("home.actions"), numeric: true }])
        end
      end
    end

    describe "rows" do
      it "has a row for each form passed to the presenter" do
        expect(presenter.data[:rows].size).to eq forms.size
      end

      it "returns the correct data for each form" do
        presenter.data[:rows].each_with_index do |row, index|
          form = forms[index]
          expect(row).to eq([
            { text: "<a class=\"govuk-link\" href=\"/forms/#{form.id}\">#{form.name}</a>" },
            { text: creator.name.to_s },
            {
              numeric: true,
              text: "<div class='app-form-states'><strong class=\"govuk-tag govuk-tag--yellow\">Draft</strong>\n</div>",
            },
          ])
        end
      end

      context "when user is org admin" do
        let(:can_admin) { true }

        it "has an additional actions column with links" do
          presenter.data[:rows].each_with_index do |row, index|
            form = forms[index]
            expect(row).to eq([
              { text: "<a class=\"govuk-link\" href=\"/forms/#{form.id}\">#{form.name}</a>" },
              { text: creator.name.to_s },
              {
                numeric: true,
                text: "<div class='app-form-states'><strong class=\"govuk-tag govuk-tag--yellow\">Draft</strong>\n</div>",
              },
              {
                numeric: true,
                text: "<a class=\"govuk-link\" href=\"/groups/#{group.external_id}/forms/#{form.id}/edit\">Change group<span class=\"govuk-visually-hidden\"> for #{form.name}</span></a>",
              },
            ])
          end
        end
      end

      context "when forms with names are random" do
        let(:forms) do
          [
            build(:form, id: 1, name: "z", created_at: "2024-10-08T07:31:15.762Z"),
            build(:form, id: 2, name: "b", created_at: "2024-10-08T07:31:15.762Z"),
            build(:form, id: 3, name: "a", created_at: "2024-10-08T07:31:15.762Z"),
            build(:form, id: 4, name: "C", created_at: "2024-10-08T07:31:15.762Z"),
          ]
        end
        let(:presenter) { described_class.call(forms:, group:, can_admin:) }

        it "sorts alphabetically" do
          rows = presenter.data[:rows]
          expect(rows[0][0][:text]).to eq("<a class=\"govuk-link\" href=\"/forms/3\">a</a>")
          expect(rows[1][0][:text]).to eq("<a class=\"govuk-link\" href=\"/forms/2\">b</a>")
          expect(rows[2][0][:text]).to eq("<a class=\"govuk-link\" href=\"/forms/4\">C</a>")
          expect(rows[3][0][:text]).to eq("<a class=\"govuk-link\" href=\"/forms/1\">z</a>")
        end
      end

      context "when multiple forms have the same name" do
        let(:forms) do
          [
            build(:form, id: 1, name: "a", created_at: "2024-10-08T07:31:15.762Z"),
            build(:form, id: 2, name: "b", created_at: "2024-10-08T07:31:15.762Z"),
            build(:form, id: 3, name: "a", created_at: "2024-10-08T08:31:15.762Z"),
            build(:form, id: 4, name: "a", created_at: "2024-10-08T09:31:15.762Z"),
          ]
        end
        let(:presenter) { described_class.call(forms:, group:, can_admin:) }

        it "sorts alphabetically first, then by created_at time" do
          rows = presenter.data[:rows]
          expect(rows[0][0][:text]).to eq("<a class=\"govuk-link\" href=\"/forms/1\">a</a>")
          expect(rows[1][0][:text]).to eq("<a class=\"govuk-link\" href=\"/forms/3\">a</a>")
          expect(rows[2][0][:text]).to eq("<a class=\"govuk-link\" href=\"/forms/4\">a</a>")
          expect(rows[3][0][:text]).to eq("<a class=\"govuk-link\" href=\"/forms/2\">b</a>")
        end
      end

      context "when a welsh version of the form exists" do
        let(:forms) do
          [
            create(:form, :live, :with_welsh_translation, id: 1, name: "form with a live Welsh Version"),
            create(:form, :archived, :with_welsh_translation, id: 2, name: "form with an archived and a draft Welsh version"),
            create(:form, :draft, :with_welsh_translation, id: 3, name: "form with Welsh draft"),
            create(:form, id: 4, name: "form with no Welsh version"),
            create(:form, :archived, :with_welsh_translation, id: 5, name: "form with only an archived Welsh version"),
          ]
        end

        before do
          # remove the draft version of the welsh translation for the form with only archived version.
          FormDocument.find_by(form: forms[4], tag: "draft", language: "cy").destroy!
        end

        it "appends the correct text" do
          rows = presenter.data[:rows]
          expect(rows[0][0][:text]).to eq("<a class=\"govuk-link\" href=\"/forms/1/live\">form with a live Welsh Version</a><p class=\"govuk-!-margin-bottom-1 govuk-!-margin-top-2 govuk-hint\">With Welsh version</p>")
          expect(rows[1][0][:text]).to eq("<a class=\"govuk-link\" href=\"/forms/2/archived\">form with an archived and a draft Welsh version</a><p class=\"govuk-!-margin-bottom-1 govuk-!-margin-top-2 govuk-hint\">With Welsh draft</p>")
          expect(rows[2][0][:text]).to eq("<a class=\"govuk-link\" href=\"/forms/4\">form with no Welsh version</a>")
          expect(rows[3][0][:text]).to eq("<a class=\"govuk-link\" href=\"/forms/5/archived\">form with only an archived Welsh version</a><p class=\"govuk-!-margin-bottom-1 govuk-!-margin-top-2 govuk-hint\">With archived Welsh version</p>")
          expect(rows[4][0][:text]).to eq("<a class=\"govuk-link\" href=\"/forms/3\">form with Welsh draft</a><p class=\"govuk-!-margin-bottom-1 govuk-!-margin-top-2 govuk-hint\">With Welsh draft</p>")
        end
      end
    end
  end
end
