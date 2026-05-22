# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class AddPfadiDeGroupAttributes < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :gruendungsdatum, :date
    add_column :groups, :aufloesungsdatum, :date
    add_column :groups, :einsichtnahme_efz_durch_gruppe, :boolean
    add_column :groups, :debitorennummer, :string
    add_column :groups, :sepa_glaeubiger_id, :string
    add_column :groups, :zahlungsart, :string
    add_column :groups, :rechtsform, :string
    add_column :groups, :strukturnummer, :string
    add_column :groups, :stamm_typ, :string
    add_column :groups, :opt_out_aufnahmeantrag, :boolean
    add_column :groups, :opt_out_aufnahmeantrag_stammessuche, :boolean
    add_column :groups, :efz_in_aufnahmeantrag, :boolean
    add_column :groups, :eingeschraenkt, :boolean
  end
end
