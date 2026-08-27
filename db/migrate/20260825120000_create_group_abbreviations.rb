# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class CreateGroupAbbreviations < ActiveRecord::Migration[7.1]
  def change
    create_table :group_abbreviations do |t|
      t.references :group, null: false
      t.string :value, null: false

      t.timestamps
    end

    add_index :group_abbreviations, :value, unique: true
  end
end
