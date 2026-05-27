# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
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
    @efz_einsichtnahmen = person.efz_einsichtnahmen.order(issued_on: :desc) if can_read_efz?
  end

  private

  def can_read_efz? = can?(:new, person.efz_einsichtnahmen.build)
end
