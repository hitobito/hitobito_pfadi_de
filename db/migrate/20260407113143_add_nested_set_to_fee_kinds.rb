# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

class AddNestedSetToFeeKinds < ActiveRecord::Migration[7.0]
  def change
    change_table :fee_kinds, bulk: true do |t|
      t.integer :lft, null: false, default: 0, index: true
      t.integer :rgt, null: false, default: 0, index: true
    end

    # Rebuild nested set structure from existing parent relationships
    reversible do |dir|
      dir.up do
        FeeKind.reset_column_information
        FeeKind.rebuild!
      end
    end
  end
end
