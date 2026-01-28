# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class CreateFeeRates < ActiveRecord::Migration[8.0]
  def change
    create_table :fee_rates do |t|
      t.references :fee_kind, foreign_key: false
      t.string :name
      t.decimal :amount, precision: 15, scale: 2, default: "0.0", null: false
      t.date :valid_from, null: false
      t.date :valid_until
      t.integer :max_member_months
      t.integer :max_age

      t.timestamps
    end
  end
end
