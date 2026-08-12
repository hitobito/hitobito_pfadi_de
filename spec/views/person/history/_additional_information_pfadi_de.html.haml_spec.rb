# frozen_string_literal: true

#  Copyright (c) 2026, Bund der Pfadfinderinnen und Pfadfinder e.V. This file is part of
#  hitobito_bdp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_bdp

require "spec_helper"

describe "person/history/_additional_information_pfadi_de.html.haml" do
  let(:person) { people(:member) }

  subject do
    render
    Capybara::Node::Simple.new(@rendered)
  end

  before do
    allow(view).to receive(:person).and_return(person.decorate)
    allow(view).to receive(:current_user).and_return(current_user)
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  context "as person with show_full permission" do
    let(:current_user) { people(:stammesverwaltung) }

    it "renders all present attrs under the Aufnahmeverfahren heading" do
      person.update!(
        membership_application_reasons: "weil ich dabei sein möchte",
        membership_application_statement_stamm: "Stamm befürwortet",
        membership_application_statement_lv: "LV befürwortet",
        membership_application_statement_bund: "Bund befürwortet",
        membership_application_process_data: "eingegangen am 01.01.2026",
        membership_application_uuid: "abcd-1234"
      )

      is_expected.to have_css "h2", text: "Aufnahmeverfahren"

      is_expected.to have_content "Begründung Aufnahmeersuchen"
      is_expected.to have_content "weil ich dabei sein möchte"

      is_expected.to have_content "Stamm befürwortet"
      is_expected.to have_content "Stellungnahme Stamm Aufnahmeersuchen"

      is_expected.to have_content "LV befürwortet"
      is_expected.to have_content "Stellungnahme LV Aufnahmeersuchen"

      is_expected.to have_content "Bund befürwortet"
      is_expected.to have_content "Stellungnahme Bund Aufnahmeersuchen"

      is_expected.to have_content "Prozessdaten Aufnahmeantrag"
      is_expected.to have_content "eingegangen am 01.01.2026"

      is_expected.to have_content "UUID Digitaler Aufnahmeantrag"
      is_expected.to have_content "abcd-1234"
    end

    it "only renders attrs that are present" do
      person.update!(membership_application_reasons: "weil ich dabei sein möchte")

      is_expected.to have_css "h2", text: "Aufnahmeverfahren"
      is_expected.to have_content "Begründung Aufnahmeersuchen"
      is_expected.to have_content "weil ich dabei sein möchte"

      is_expected.not_to have_content "Stellungnahme Stamm Aufnahmeersuchen"
      is_expected.not_to have_content "Stellungnahme LV Aufnahmeersuchen"
      is_expected.not_to have_content "Stellungnahme Bund Aufnahmeersuchen"
      is_expected.not_to have_content "Prozessdaten Aufnahmeantrag"
      is_expected.not_to have_content "UUID Digitaler Aufnahmeantrag"
    end

    it "renders nothing if no membership application data is present" do
      is_expected.not_to have_css "h2", text: "Aufnahmeverfahren"
    end
  end

  context "as the person herself" do
    let(:current_user) { person }

    it "renders the section on her own history" do
      person.update!(membership_application_reasons: "weil ich dabei sein möchte")

      is_expected.to have_css "h2", text: "Aufnahmeverfahren"
      is_expected.to have_content "weil ich dabei sein möchte"
    end
  end

  context "as person without show_full permission" do
    let(:current_user) {
      Fabricate(Group::StammGruppePfadfinder::Leitung.sti_name, group: groups(:pfadfinder)).person
    }

    it "renders nothing, even if data is present" do
      person.update!(membership_application_reasons: "weil ich dabei sein möchte")

      is_expected.not_to have_css "h2", text: "Aufnahmeverfahren"
      is_expected.not_to have_content "weil ich dabei sein möchte"
    end
  end
end
