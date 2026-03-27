# frozen_string_literal: true

require "spec_helper"

describe :self_registration do
  subject { page }

  let(:group) { groups(:adler_mitglieder) }
  let!(:default_fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }
  let!(:other_fee_kind) {
    Fabricate(:fee_kind, parent: fee_kinds(:top_fee_kind),
      layer: groups(:baden_wuerttemberg), name: "Other Fee Kind")
  }
  let!(:foerder_fee_kind) {
    Fabricate(:fee_kind, layer: groups(:root), name: "Förderbeitragsart",
      role_type: "Group::Mitglieder::Foerdermitgliedschaft")
  }

  before do
    group.update!(self_registration_role_type: Group::Mitglieder::OrdentlicheMitgliedschaft.name)

    visit group_self_registration_path(group_id: group)
  end

  it "allows to manually set a fee kind" do
    fill_in "Vorname", with: "Max"
    fill_in "Nachname", with: "Muster"
    fill_in "Haupt-E-Mail", with: "max.muster@hitobito.example.com"
    expect(page).to(have_text("BaWü Kind"))
    expect(page).to(have_text("Other Fee Kind"))
    expect(page).not_to(have_text("Förderbeitragsart"))
    select "Other Fee Kind", from: "Beitragsart"

    expect do
      find_all('.btn-toolbar .btn-group button[type="submit"]').first.click

      is_expected.to have_text(
        "Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine E-Mail mit der " \
          "Anleitung, wie Du Deinen Account freischalten kannst."
      )
    end.to change { Person.count }.by(1)
      .and change { Role.count }.by(1)

    person = Person.find_by(email: "max.muster@hitobito.example.com")
    expect(person).to be_present
    expect(person.roles.first.fee_kind_id).to eq(other_fee_kind.id)
  end

  context "if no fee kind id specified" do
    it "chooses a default fee kind" do
      fill_in "Vorname", with: "Max"
      fill_in "Nachname", with: "Muster"
      fill_in "Haupt-E-Mail", with: "max.muster@hitobito.example.com"

      expect do
        find_all('.btn-toolbar .btn-group button[type="submit"]').first.click

        is_expected.to have_text(
          "Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine E-Mail mit der " \
            "Anleitung, wie Du Deinen Account freischalten kannst."
        )
      end.to change { Person.count }.by(1)
        .and change { Role.count }.by(1)

      person = Person.find_by(email: "max.muster@hitobito.example.com")
      expect(person).to be_present
      expect(person.roles.first.fee_kind_id).to eq(default_fee_kind.id)
    end
  end

  context "with role type without fee kind" do
    before do
      group.update!(self_registration_role_type: Group::Mitglieder::Zweitmitgliedschaft.name)

      visit group_self_registration_path(group_id: group)
    end

    it "does not allow to set a fee kind" do
      fill_in "Vorname", with: "Max"
      fill_in "Nachname", with: "Muster"
      fill_in "Haupt-E-Mail", with: "max.muster@hitobito.example.com"
      expect(page).not_to(have_text("Beitragsart"))
      expect(page).not_to(have_text("BaWü Kind"))
      expect(page).not_to(have_text("Other Fee Kind"))

      expect do
        find_all('.btn-toolbar .btn-group button[type="submit"]').first.click

        is_expected.to have_text(
          "Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine E-Mail mit der " \
            "Anleitung, wie Du Deinen Account freischalten kannst."
        )
      end.to change { Person.count }.by(1)
        .and change { Role.count }.by(1)

      person = Person.find_by(email: "max.muster@hitobito.example.com")
      expect(person).to be_present
      expect(person.roles.first.fee_kind_id).to be_nil
    end
  end
end
