# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module EfzHelper
  def can_read_efz_einsichtnahme?(person = entry)
    can?(:read, EfzEinsichtnahme.new(person:))
  end

  def can_create_efz_einsichtnahme?(person = entry)
    current_ability.can?(:create, EfzEinsichtnahme.new(person:))
  end
end
