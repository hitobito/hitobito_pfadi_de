# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe ContactAccountCategory do
  describe "efz_address" do
    it "is efz_address? for efz_address category" do
      category = contact_account_categories(:additional_address_group_efz_address)
      expect(category).to be_efz_address
    end

    it "is valid when efz_address is set and unique_per_contactable is true" do
      category = contact_account_categories(:additional_address_group_efz_address)
      expect(category).to be_valid
    end

    it "is invalid when efz_address is set but unique_per_contactable is false" do
      category = ContactAccountCategory.new(
        contact_account_type: "AdditionalAddress",
        contactable_type: "Group",
        key: "invalid",
        unique_per_contactable: false,
        efz_address: true
      )
      category.name = "Invalid"
      expect(category).not_to be_valid
      expect(category.errors[:unique_per_contactable]).to be_present
    end
  end
end
