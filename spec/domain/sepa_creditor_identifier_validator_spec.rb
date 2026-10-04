# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe SepaCreditorIdentifierValidator do
  subject(:validator) { described_class.new(attributes: [:sepa_glaeubiger_id]) }

  %w[DE98ZZZ09999999999 de98zzz09999999999 AT61ZZZ01234567890].each do |value|
    it "accepts #{value}" do
      expect(validator.valid_creditor_identifier?(value)).to be true
    end
  end

  {
    "wrong check digits" => "DE02ZZZ09999999999",
    "wrong german length" => "DE98ZZZ0999999999",
    "letters in german national id" => "DE98ZZZ0999999999A",
    "invalid format" => "123",
    "iban" => "DE02120300000000202051"
  }.each do |description, value|
    it "rejects #{description}" do
      expect(validator.valid_creditor_identifier?(value)).to be false
    end
  end

  describe "on layer groups" do
    let(:group) { groups(:adler) }

    it "normalizes and validates the creditor identifier" do
      group.sepa_glaeubiger_id = "de98 zzz0 9999 9999 99"

      expect(group).to be_valid
      expect(group.sepa_glaeubiger_id).to eq "DE98ZZZ09999999999"
    end

    it "adds an error for an invalid creditor identifier" do
      group.sepa_glaeubiger_id = "DE02ZZZ09999999999"

      expect(group).to have(1).error_on(:sepa_glaeubiger_id)
    end

    it "does not validate an unchanged creditor identifier" do
      group.update_columns(sepa_glaeubiger_id: "invalid")

      expect(group.reload).to be_valid
    end

    it "requires a creditor identifier to enable sepa mandates" do
      group.sepa_mandate_mode = "required"

      expect(group).to have(1).error_on(:sepa_mandate_mode)
      expect(group).not_to be_sepa_mandates_enabled

      group.sepa_glaeubiger_id = "DE98ZZZ09999999999"
      expect(group).to be_valid
      expect(group).to be_sepa_mandates_enabled
    end

    it "is inactive by default" do
      expect(group.sepa_mandate_mode).to eq "inactive"
      expect(group).not_to be_sepa_mandates_enabled
    end
  end
end
