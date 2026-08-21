# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe Person do
  it "includes latest_efz_issued_on in FILTER_ATTRS" do
    expect(Person::FILTER_ATTRS).to include :latest_efz_issued_on
  end

  describe "PaperTrail", versioning: true do
    let(:person) { people(:member) }

    it "ignores last_entry_date_with_fee_kind changes" do
      expect do
        person.update!(last_entry_date_with_fee_kind: Date.current)
      end.not_to change { person.versions.count }
    end

    it "ignores should_recalculate_last_entry_date_with_fee_kind changes" do
      expect do
        person.update!(should_recalculate_last_entry_date_with_fee_kind: true)
      end.not_to change { person.versions.count }
    end

    it "tracks other attribute changes normally" do
      expect do
        person.update!(first_name: "NewName")
      end.to change { person.versions.count }

      expect(person.versions.last.changeset).to have_key("first_name")
    end
  end

  describe "#leading_layer" do
    let(:person) { people(:member) }
    let(:group) { groups(:adler_mitglieder) }

    it "is the layer group of the person's active Ordentliche Mitgliedschaft" do
      expect(person.leading_layer).to eq group.layer_group
      expect(person.leading_layer_role).to eq roles(:paying_member)
    end

    it "is nil when the person holds no active role at all" do
      roles(:paying_member).destroy
      roles(:member).destroy

      expect(person.leading_layer_role).to be_nil
      expect(person.leading_layer).to be_nil
    end

    it "counts Foerdermitgliedschaft as a membership role too" do
      roles(:paying_member).destroy
      fee_kind = Fabricate(:fee_kind, layer: Group.roots.first,
        role_type: Group::Mitglieder::Foerdermitgliedschaft.sti_name)
      foerdermitgliedschaft = Fabricate(Group::Mitglieder::Foerdermitgliedschaft.sti_name,
        group:, person:, fee_kind:)

      expect(person.leading_layer_role).to eq foerdermitgliedschaft
    end

    it "prefers the role that started earliest when several official membership roles are active at once" do
      other_group = groups(:mitglieder_28)
      older_role = Fabricate(
        Group::Mitglieder::OrdentlicheMitgliedschaft.sti_name,
        group: other_group,
        person:,
        fee_kind: fee_kinds(:baden_wuerttemberg_kind),
        start_on: roles(:paying_member).start_on - 1.year
      )

      expect(person.leading_layer_role).to eq older_role
    end

    it "falls back to the longest-ongoing role of any type when no official " \
      "membership role exists" do
      roles(:paying_member).destroy
      older_role = Fabricate(Group::Mitglieder::Zweitmitgliedschaft.sti_name,
        group: groups(:mitglieder_28), person:, start_on: "2020-01-01")

      expect(person.leading_layer_role).to eq older_role
      expect(person.leading_layer).to eq groups(:mitglieder_28).layer_group
    end

    it "never picks a role that has already ended, however early it started" do
      ended_role = Fabricate(
        Group::Mitglieder::OrdentlicheMitgliedschaft.sti_name,
        group: groups(:mitglieder_28),
        person:,
        fee_kind: fee_kinds(:baden_wuerttemberg_kind),
        start_on: "2000-01-01",
        end_on: "2000-12-31"
      )
      ongoing_role = roles(:paying_member)

      expect(person.send(:earliest_role, [ended_role, ongoing_role])).to eq ongoing_role
    end
  end
end
