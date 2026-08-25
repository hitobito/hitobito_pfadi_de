# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::LayerGroup
  extend ActiveSupport::Concern

  included do
    self.used_attributes += [
      :gruendungsdatum,
      :aufloesungsdatum,
      :einsichtnahme_efz_durch_gruppe,
      :bank_account_owner,
      :iban,
      :bic,
      :bank_name,
      :debitorennummer,
      :sepa_glaeubiger_id,
      :zahlungsart
    ]

    i18n_enum :zahlungsart, %w[rechnung lastschrift],
      i18n_prefix: "activerecord.attributes.group.zahlungsarten"

    i18n_enum :rechtsform, %w[ev kein_ev unbekannt],
      i18n_prefix: "activerecord.attributes.group.rechtsformen"
  end
end
