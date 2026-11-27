# frozen_string_literal: true

#  Copyright (c) 2025-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Person::HistoryController
  extend ActiveSupport::Concern

  prepended do
    alias_method :person, :entry
    helper_method :person, :group
  end

  def index
    super
    @efz_einsichtnahmen = person.efz_einsichtnahmen.order(issued_on: :desc)
  end

  private

  def history_section_sizes
    sizes = super
    sizes += [@efz_einsichtnahmen.size] if helpers.can_read_efz_einsichtnahme?(person)
    sizes += [1] if helpers.can_read_membership_application_attrs?(person)
    sizes
  end
end
