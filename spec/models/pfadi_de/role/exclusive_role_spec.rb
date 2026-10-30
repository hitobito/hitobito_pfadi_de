# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe PfadiDe::Role::ExclusiveRole do
  let(:person) { people(:member) }
  let(:other_person) { people(:bottom_leader) }

  # layer: adler (Stamm)
  let(:adler_mitglieder) { groups(:adler_mitglieder) }
  # layer: baden_wuerttemberg (Landesverband)
  let(:mitglieder_bw) { groups(:mitglieder_bw) }

  # OrdentlicheMitgliedschaft of `member` in adler_mitglieder, starting 2026-01-01, open ended
  let!(:existing_role) { roles(:paying_member) }

  let(:validate_past) { false }

  around do |example|
    registry = described_class.registry.dup
    example.run
    described_class.registry.replace(registry)
  end

  before do
    Group::Mitglieder::OrdentlicheMitgliedschaft
      .mutually_exclusive_in(:membership, scope: :layer, validate_past:)
    Group::Mitglieder::Zweitmitgliedschaft
      .mutually_exclusive_in(:membership, scope: :layer, validate_past:)
  end

  def build_role(type, person: self.person, group: adler_mitglieder, start_on: Date.current,
    end_on: nil)
    type.new(person: person, group: group, start_on: start_on, end_on: end_on)
  end

  it "is valid for a role without registered categories" do
    role = Group::StammGruppePfadfinder::Mitglied
      .new(person: person, group: groups(:pfadfinder))

    expect(role).to be_valid
  end

  describe "scope :layer" do
    it "rejects a same-category role overlapping in the same layer" do
      role = build_role(Group::Mitglieder::Zweitmitgliedschaft)

      expect(role).not_to be_valid
      expect(role.errors[:base].first).to include("Ordentliche")
    end

    it "includes group, layer and period of the conflicting role in the error" do
      role = build_role(Group::Mitglieder::Zweitmitgliedschaft)

      expect(role).not_to be_valid
      expect(role.errors[:base].first)
        .to include("Adler / Mitglieder")
        .and include("01.01.2026")
        .and include("offen")
    end

    it "accepts a same-category role in a different layer" do
      role = build_role(Group::Mitglieder::Zweitmitgliedschaft, group: mitglieder_bw)

      expect(role).to be_valid
    end

    it "accepts the role for a different person in the same layer" do
      role = build_role(Group::Mitglieder::Zweitmitgliedschaft, person: other_person)

      expect(role).to be_valid
    end
  end

  describe "scope :global" do
    before do
      described_class.registry.clear
      Group::Mitglieder::OrdentlicheMitgliedschaft
        .mutually_exclusive_in(:membership, scope: :global)
      Group::Mitglieder::Zweitmitgliedschaft
        .mutually_exclusive_in(:membership, scope: :global)
    end

    it "rejects a same-category role in a different layer" do
      role = build_role(Group::Mitglieder::Zweitmitgliedschaft, group: mitglieder_bw)

      expect(role).not_to be_valid
    end

    it "accepts a same-category role for a different person in the same layer" do
      role = build_role(Group::Mitglieder::Zweitmitgliedschaft, person: other_person)

      expect(role).to be_valid
    end
  end

  describe "unrelated categories" do
    before do
      described_class.registry.clear
      Group::Mitglieder::OrdentlicheMitgliedschaft
        .mutually_exclusive_in(:membership, scope: :global)
      Group::Mitglieder::Zweitmitgliedschaft
        .mutually_exclusive_in(:honorary, scope: :global)
    end

    it "accepts roles of a different category" do
      role = build_role(Group::Mitglieder::Zweitmitgliedschaft, group: mitglieder_bw)

      expect(role).to be_valid
    end
  end

  describe "validity periods" do
    it "accepts a role starting after the conflicting role ends" do
      existing_role.update_columns(end_on: 1.month.ago.to_date)

      role = build_role(Group::Mitglieder::Zweitmitgliedschaft)

      expect(role).to be_valid
    end

    it "rejects a role overlapping an open-ended conflicting role" do
      role = build_role(Group::Mitglieder::Zweitmitgliedschaft,
        start_on: 3.months.from_now.to_date)

      expect(role).not_to be_valid
    end

    it "accepts a role within a gap of the conflicting role" do
      existing_role.update_columns(
        start_on: 6.months.ago.to_date,
        end_on: 3.months.ago.to_date
      )

      role = build_role(Group::Mitglieder::Zweitmitgliedschaft,
        start_on: 2.months.ago.to_date)

      expect(role).to be_valid
    end

    it "does not conflict with itself when updated" do
      existing_role.end_on = 1.year.from_now.to_date

      expect(existing_role).to be_valid
    end
  end

  describe "validate_past" do
    context "with validate_past: false" do
      let(:validate_past) { false }

      it "allows mutations entirely in the past with validate_past: false" do
        existing_role.update_columns(
          start_on: 1.year.ago.to_date,
          end_on: 3.months.ago.to_date
        )

        role = build_role(Group::Mitglieder::Zweitmitgliedschaft,
          start_on: 6.months.ago.to_date, end_on: 4.months.ago.to_date)

        expect(role).to be_valid
      end

      it "allows corrections with past start_on overlapping an ended role" do
        # existing role ended yesterday, new role was backdated: only [today..] is checked
        existing_role.update_columns(
          start_on: 1.year.ago.to_date,
          end_on: Date.yesterday
        )

        role = build_role(Group::Mitglieder::Zweitmitgliedschaft,
          start_on: 2.months.ago.to_date)

        expect(role).to be_valid
      end

      context "with a pre-existing overlapping role" do
        let!(:overlapping_role) do
          build_role(Group::Mitglieder::Zweitmitgliedschaft,
            start_on: 6.months.ago.to_date).tap { |role| role.save!(validate: false) }
        end

        # soft destroy only applies to roles older than minimum_days_to_archive
        before { existing_role.update_columns(created_at: 2.months.ago) }

        it "soft-destroys the role despite the overlap (only [today..] is checked)" do
          expect { existing_role.destroy }.not_to raise_error

          expect(existing_role.end_on).to eq Date.yesterday
        end
      end
    end

    context "with validate_past: true" do
      let(:validate_past) { true }

      it "rejects overlaps entirely in the past" do
        existing_role.update_columns(
          start_on: 1.year.ago.to_date,
          end_on: 3.months.ago.to_date
        )

        role = build_role(Group::Mitglieder::Zweitmitgliedschaft,
          start_on: 6.months.ago.to_date, end_on: 4.months.ago.to_date)

        expect(role).not_to be_valid
      end

      it "rejects a role without start overlapping in the past" do
        existing_role.update_columns(
          start_on: 1.year.ago.to_date,
          end_on: 3.months.ago.to_date
        )

        role = build_role(Group::Mitglieder::Zweitmitgliedschaft,
          start_on: nil, end_on: 4.months.ago.to_date)

        expect(role).not_to be_valid
      end

      context "with a pre-existing overlapping role" do
        let!(:overlapping_role) do
          build_role(Group::Mitglieder::Zweitmitgliedschaft,
            start_on: 6.months.ago.to_date).tap { |role| role.save!(validate: false) }
        end

        # soft destroy only applies to roles older than minimum_days_to_archive
        before { existing_role.update_columns(created_at: 2.months.ago) }

        it "prevents ending the role via update" do
          expect(existing_role.update(end_on: Date.yesterday)).to be false
          expect(existing_role.errors[:base].first).to include("Zweitmitgliedschaft")
        end

        it "prevents soft-destroying the role (change_type raises RecordInvalid)" do
          expect { existing_role.destroy }.to raise_error(ActiveRecord::RecordInvalid)

          expect(existing_role.reload.end_on).to be_nil
        end
      end
    end
  end

  describe ".mutually_exclusive_in" do
    it "registers the role type in the registry" do
      expect(described_class.registry).to include(
        described_class::Exclusion.new(
          type: Group::Mitglieder::OrdentlicheMitgliedschaft,
          category: :membership,
          scope: :layer,
          validate_past: false
        )
      )
    end

    it "rejects an unknown scope" do
      expect do
        Group::Mitglieder::Foerdermitgliedschaft
          .mutually_exclusive_in(:membership, scope: :company)
      end.to raise_error(ArgumentError)
    end

    it "is idempotent for identical declarations" do
      expect do
        Group::Mitglieder::OrdentlicheMitgliedschaft
          .mutually_exclusive_in(:membership, scope: :layer)
      end.not_to change { described_class.registry.size }
    end

    it "replaces scope and validate_past when the category is re-declared" do
      expect do
        Group::Mitglieder::OrdentlicheMitgliedschaft
          .mutually_exclusive_in(:membership, scope: :global, validate_past: true)
      end.not_to change { described_class.registry.size }

      expect(described_class.registry).to include(
        described_class::Exclusion.new(
          type: Group::Mitglieder::OrdentlicheMitgliedschaft,
          category: :membership,
          scope: :global,
          validate_past: true
        )
      )
    end
  end
end
