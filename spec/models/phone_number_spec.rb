# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe PhoneNumber do
  let(:person) { Fabricate(:person) }

  let!(:private_number) do
    Fabricate(:phone_number, contactable: person,
      category: contact_account_categories(:phone_number_person_private))
  end
  let!(:work_number) do
    Fabricate(:phone_number, contactable: person,
      category: contact_account_categories(:phone_number_person_work))
  end

  it ".home finds numbers of the private category" do
    expect(person.phone_numbers.home).to eq [private_number]
  end
end
