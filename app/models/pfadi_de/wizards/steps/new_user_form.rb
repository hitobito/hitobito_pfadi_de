# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Wizards::Steps::NewUserForm
  extend ActiveSupport::Concern

  prepended do
    self.support_company = false

    attribute :fee_kind_id, :integer

    # Geburtsdatum and Anschrift are Pflichtfelder for members
    # (see PfadiDe::Person::MEMBER_REQUIRED_ATTRS). Wizards::RegisterNewUserWizard
    # passes every attribute of this step on to the person.
    attribute :birthday, :date
    attribute :address_care_of, :string
    attribute :street, :string
    attribute :housenumber, :string
    attribute :postbox, :string
    attribute :zip_code, :string
    attribute :town, :string
    attribute :country, :string
  end
end
