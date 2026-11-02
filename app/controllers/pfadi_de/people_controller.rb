# frozen_string_literal: true

#  Copyright (c) 2025-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::PeopleController
  extend ActiveSupport::Concern

  class_methods do
    def sort_mappings_with_indifferent_access
      super.merge(
        entry_date: "people.last_entry_date_with_fee_kind",
        exit_date: "people.last_exit_date_with_fee_kind"
      ).with_indifferent_access
    end
  end

  def permitted_attrs
    attrs = super + PfadiDe::Contactable::BANK_ACCOUNT_ATTRS +
      [:pronoun, :consent_data_retention]

    return attrs unless entry.self_or_managed_by_current_person?

    attrs - PfadiDe::Person::SELF_OR_MANAGED_RESTRICTED_ATTRS.map(&:to_sym)
  end
end
