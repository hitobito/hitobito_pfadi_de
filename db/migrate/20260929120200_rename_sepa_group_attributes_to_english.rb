# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

class RenameSepaGroupAttributesToEnglish < ActiveRecord::Migration[8.0]
  def change
    rename_column :groups, :zahlungsart, :payment_method
    rename_column :groups, :sepa_glaeubiger_id, :sepa_creditor_id
  end
end
