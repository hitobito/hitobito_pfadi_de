# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::PeopleController
  extend ActiveSupport::Concern

  prepended do
    helper_method :can_read_efz_einsichtnahme?, :can_create_efz_einsichtnahme?
  end

  def permitted_attrs
    super + PfadiDe::Contactable::BANK_ACCOUNT_ATTRS +
      [:pronoun, :exit_date, :payment_method, :consent_data_retention]
  end

  private

  def can_read_efz_einsichtnahme? = current_ability.can?(:read, EfzEinsichtnahme.new(person: entry))

  def can_create_efz_einsichtnahme?
    current_ability.can?(:create, EfzEinsichtnahme.new(person: entry))
  end
end
