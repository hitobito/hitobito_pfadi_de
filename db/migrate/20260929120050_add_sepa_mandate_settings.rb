# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

class AddSepaMandateSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :groups, :sepa_mandate_mode, :string, null: false, default: "inactive"
    add_column :service_tokens, :sepa_mandates, :boolean, null: false, default: false
  end
end
