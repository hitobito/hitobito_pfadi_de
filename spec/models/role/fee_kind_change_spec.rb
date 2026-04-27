# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Role::FeeKindChange do
  let(:fee_kind) {
    Fabricate(:fee_kind, name: "BAWÜ Jugend", layer: groups(:baden_wuerttemberg),
      parent: fee_kinds(:top_fee_kind))
  }

  let(:attributes) { {start_on: Time.zone.today, fee_kind_id: fee_kind.id} }
  let(:person) { role.person }
  let(:role) { roles(:paying_member) }

  before { travel_to(Time.zone.local(2026, 4, 30)) }

  subject { described_class.new(role, attributes) }

  describe "::validations" do
    it "is valid" do
      expect(subject).to be_valid
    end

    it "validates fee_kind presence" do
      attributes[:fee_kind_id] = ""
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["Beitragsart ist nicht gültig"]
    end

    it "validates fee_kind exists" do
      attributes[:fee_kind_id] = -1
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["Beitragsart ist nicht gültig"]
    end

    it "validates fee_kind is one of the possible fee_kinds" do
      attributes[:fee_kind_id] = fee_kinds(:top_fee_kind).id
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["Beitragsart ist nicht gültig"]
    end

    it "validates fee_kind differs from current fee kind" do
      attributes[:fee_kind_id] = role.fee_kind_id
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["Beitragsart ist nicht gültig"]
    end

    it "validates start_on is after role start_on" do
      attributes[:start_on] = role.start_on
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["Ab muss nach 01.01.2026 sein"]
    end

    it "validates start_on is before role end_on" do
      role.update!(end_on: "2026-12-31")
      attributes[:start_on] = role.end_on
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["Ab muss vor 31.12.2026 sein"]
    end
  end

  describe "#save!" do
    it "ends existing and creates new role with new fee_kind" do
      expect do
        expect(subject.save!).to be_truthy
      end.to change { role.reload.end_on }.to(attributes[:start_on] - 1.day)
      expect(person.roles.last.fee_kind).to eq fee_kind
      expect(person.roles.last.start_on).to eq Time.zone.today
      expect(person.roles.last.end_on).to be_nil
    end

    it "copies end_of of existing to new role" do
      role.update!(end_on: "2026-12-31")
      expect do
        expect(subject.save!).to be_truthy
      end.to change { role.reload.end_on }.to(attributes[:start_on] - 1.day)
      expect(person.roles.last.fee_kind).to eq fee_kind
      expect(person.roles.last.start_on).to eq Time.zone.today
      expect(person.roles.last.end_on.to_s).to eq "2026-12-31"
    end

    it "raises if invalid" do
      attributes[:start_on] = "2025-01-01"
      expect { subject.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
