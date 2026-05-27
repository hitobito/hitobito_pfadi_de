# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

Fabricator(:efz_einsichtnahme) do
  person
  einsichtnehmer(fabricator: :person)
  einsicht_on { Date.current }
  issued_on { 1.week.ago.to_date }
  confirmation "1"
end
