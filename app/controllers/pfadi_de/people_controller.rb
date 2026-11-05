# frozen_string_literal: true

#  Copyright (c) 2025-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::PeopleController
  extend ActiveSupport::Concern

  def permitted_attrs
    attrs = super + PfadiDe::Contactable::BANK_ACCOUNT_ATTRS +
      [:pronoun, :consent_data_retention]

    return attrs unless entry.self_or_managed_by_current_person?

    attrs - PfadiDe::Person::SELF_OR_MANAGED_RESTRICTED_ATTRS.map(&:to_sym)
  end
end
