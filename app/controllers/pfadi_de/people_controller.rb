# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::PeopleController
  extend ActiveSupport::Concern

  # Removes restricted attributes from permitted_attrs when a person edits their own
  # profile, or a manager edits the profile of a person they manage. This prevents
  # self- or manager-submitted changes to payment and identity data via strong parameters.
  def permitted_attrs
    attrs = super + PfadiDe::Contactable::BANK_ACCOUNT_ATTRS +
      [:pronoun, :payment_method, :consent_data_retention]

    return attrs unless entry.self_or_managed_by?(current_user)

    attrs - PfadiDe::Person::SELF_OR_MANAGED_RESTRICTED_ATTRS.map(&:to_sym)
  end
end
