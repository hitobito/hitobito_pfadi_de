# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

class AddLastEntryDateWithFeeKindToPeople < ActiveRecord::Migration[7.0]
  def change
    change_table :people, bulk: true do |t|
      t.date :last_entry_date_with_fee_kind, null: true
      t.boolean :should_recalculate_last_entry_date_with_fee_kind,
        default: false, null: false

      t.index :last_entry_date_with_fee_kind,
        name: "index_people_on_last_entry_date_fee_kind"
      t.index :should_recalculate_last_entry_date_with_fee_kind,
        name: "index_people_on_should_recalc_last_entry_date_fee_kind"
    end

    # Alle bestehenden Personen zur Neuberechnung markieren
    reversible do |dir|
      dir.up do
        Person.update_all(should_recalculate_last_entry_date_with_fee_kind: true)
      end
    end
  end
end
