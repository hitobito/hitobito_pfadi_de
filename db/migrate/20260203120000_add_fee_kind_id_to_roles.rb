# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class AddFeeKindIdToRoles < ActiveRecord::Migration[8.0]
  def change
    add_column :roles, :fee_kind_id, :integer, null: true
  end
end
