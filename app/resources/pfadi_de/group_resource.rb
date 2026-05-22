# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::GroupResource
  extend ActiveSupport::Concern

  prepended do
    with_options writable: false do
      attribute :bank_account_owner, :string
      attribute :iban, :string
      attribute :bic, :string
      attribute :bank_name, :string
      attribute :gruendungsdatum, :date
      attribute :aufloesungsdatum, :date
      attribute :einsichtnahme_efz_durch_gruppe, :boolean
      attribute :debitorennummer, :string
      attribute :sepa_glaeubiger_id, :string
      attribute :zahlungsart, :string
      attribute :rechtsform, :string
      attribute :strukturnummer, :string
      attribute :stamm_typ, :string
      attribute :opt_out_aufnahmeantrag, :boolean
      attribute :opt_out_aufnahmeantrag_stammessuche, :boolean
      attribute :efz_in_aufnahmeantrag, :boolean
      attribute :eingeschraenkt, :boolean
    end
  end
end
