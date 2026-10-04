# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe SepaMandate do
  let(:person) { people(:member) }
  let(:group) { groups(:adler) }
  let(:admin) { people(:admin) }

  before do
    group.update!(sepa_mandate_mode: "optional", sepa_glaeubiger_id: "DE98ZZZ09999999999")
    person.update!(iban: "DE02 1203 0000 0000 2020 51")
  end

  def build_mandate(**attrs)
    SepaMandate.new(person:, group:, issued_at: Time.zone.now, valid_from: Time.zone.today,
      confirmation: true, **attrs)
  end

  describe "creation" do
    it "generates the reference from group, person and a random stamp" do
      mandate = build_mandate
      mandate.save!

      expect(mandate.reference).to match(/\A#{group.id}-#{person.id}-[0-9A-F]{4}\z/)
      expect(mandate.reference.length).to be <= 35
    end

    it "keeps a given reference" do
      mandate = build_mandate(reference: "IMPORT-4711")
      mandate.save!

      expect(mandate.reference).to eq "IMPORT-4711"
    end

    it "validates the reference format" do
      expect(build_mandate(reference: "with space")).to have(1).error_on(:reference)
      expect(build_mandate(reference: "Ümlaut")).to have(1).error_on(:reference)
      expect(build_mandate(reference: "A" * 36)).to have(1).error_on(:reference)
    end

    it "validates uniqueness of the reference" do
      build_mandate(reference: "IMPORT-4711").save!

      mandate = build_mandate(reference: "IMPORT-4711")
      expect(mandate).to have(1).error_on(:reference)
    end

    it "sets the default evidence" do
      mandate = build_mandate
      mandate.save!

      expect(mandate.evidence).to eq "Hitobito-Gruppierung"
    end

    it "requires the confirmation" do
      expect(build_mandate(confirmation: nil)).to have(1).error_on(:confirmation)
    end

    it "requires a layer group" do
      expect(build_mandate(group: groups(:pfadfinder))).to have(1).error_on(:group)
    end

    it "requires sepa mandates to be enabled on the group" do
      group.update!(sepa_mandate_mode: "inactive")

      expect(build_mandate).to have(1).error_on(:group)
    end

    it "requires an iban on the person" do
      person.update!(iban: nil)

      expect(build_mandate).to have(1).error_on(:person)
    end

    it "revokes the active mandate of the same person and group" do
      old = build_mandate(creator: admin)
      old.save!
      other_group = build_mandate(group: groups(:silberreiher))
      groups(:silberreiher).update!(sepa_mandate_mode: "required",
        sepa_glaeubiger_id: "DE98ZZZ09999999999")
      other_group.save!

      build_mandate(creator: admin).save!

      expect(old.reload).not_to be_active
      expect(old.revoker).to eq admin
      expect(other_group.reload).to be_active
      expect(person.sepa_mandates.active.count).to eq 2
    end

    it "is tracked on the person's log", versioning: true do
      expect { build_mandate.save! }
        .to change { PaperTrail::Version.where(main_id: person.id, main_type: Person.sti_name).count }
        .by(1)
    end
  end

  describe "immutability" do
    let(:mandate) { build_mandate.tap(&:save!) }

    it "cannot be changed" do
      mandate.valid_from = Time.zone.tomorrow

      expect(mandate).not_to be_valid
      expect(mandate.errors[:base]).to be_present
    end

    it "cannot be revoked in the future" do
      mandate.revoked_at = 1.day.from_now

      expect(mandate).to have(1).error_on(:revoked_at)
    end

    it "can be revoked once" do
      mandate.revoke!(admin)

      expect(mandate.reload.status).to eq :revoked
      expect(mandate.revoked_at).to be_present
      expect(mandate.revoker).to eq admin
      expect { mandate.revoke!(admin) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "bank account changes of the person" do
    let!(:mandate) { build_mandate.tap(&:save!) }

    it "revokes active mandates when the iban changes" do
      Auth.current_person = admin
      person.update!(iban: "DE89 3704 0044 0532 0130 00")

      expect(mandate.reload).not_to be_active
      expect(mandate.revoker).to eq admin
    ensure
      Auth.current_person = nil
    end

    it "revokes active mandates when the bic changes" do
      person.update!(bic: "COBADEFFXXX")

      expect(mandate.reload).not_to be_active
      expect(mandate.revoker).to be_nil
    end

    it "revokes active mandates when the bank account owner changes" do
      person.update_columns(bank_account_owner: "Max Muster")
      person.update!(bank_account_owner: "Erika Muster")
      expect(mandate.reload).not_to be_active
    end

    it "does not revoke mandates for formatting changes of the bank account owner" do
      person.update_columns(bank_account_owner: "Max Muster")
      person.update!(bank_account_owner: " max  muster ")

      expect(mandate.reload).to be_active
    end

    it "does not revoke mandates for formatting changes" do
      person.update!(iban: "DE02120300000000202051")

      expect(mandate.reload).to be_active
    end

    it "does not revoke mandates for other changes" do
      person.update!(first_name: "Changed", bank_name: "Other Bank")

      expect(mandate.reload).to be_active
    end
  end

  describe "Person#payment_method" do
    it "is invoice without active mandate" do
      expect(person.payment_method).to eq "invoice"
      expect(person.payment_method_label).to eq "Überweisung"
    end

    it "is debit with an active mandate" do
      mandate = build_mandate.tap(&:save!)

      expect(person.reload.payment_method).to eq "debit"
      expect(person.payment_method_label).to eq "Lastschrift"
      expect(person.sepa_mandate_references).to eq mandate.reference
    end

    it "is invoice again once the mandate is revoked" do
      build_mandate.tap(&:save!).revoke!

      expect(person.reload.payment_method).to eq "invoice"
    end
  end
end
