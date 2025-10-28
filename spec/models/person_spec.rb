# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Person do
  let(:person) { people(:member) }

  subject { person }

  describe "entry_date" do
    before { person.roles.first.update(start_on: "2025-08-01") }

    its(:entry_date) { should eq Date.parse("2025-08-01") }
  end

  describe "iban" do
    before { person.iban = "DE00 0000 0000" }

    it "is validated" do
      expect(person).not_to be_valid
      expect(person.errors[:iban]).to include(I18n.t("errors.messages.invalid_iban"))
    end
  end
end
