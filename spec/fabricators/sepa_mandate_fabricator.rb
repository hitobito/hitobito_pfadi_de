# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

Fabricator(:sepa_mandate) do
  person
  issued_at { Time.zone.now }
  valid_from { Time.zone.today }
  confirmation { true }

  # mandates require an enabled creditor and a bank account on the person
  after_build do |mandate|
    unless mandate.group.sepa_mandates_enabled?
      mandate.group.update_columns(sepa_mandate_mode: "optional",
        sepa_glaeubiger_id: "DE98ZZZ09999999999")
    end
    mandate.person.update_columns(iban: "DE02120300000000202051") if mandate.person.iban.blank?
  end
end
