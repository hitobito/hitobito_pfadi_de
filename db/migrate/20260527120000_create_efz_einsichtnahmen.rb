# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

class CreateEfzEinsichtnahmen < ActiveRecord::Migration[8.0]
  def change
    create_table :efz_einsichtnahmen do |t|
      t.references :person, null: false, index: true
      t.references :einsichtnehmer, null: false, index: true
      t.date :einsicht_on, null: false
      t.date :issued_on, null: false

      t.timestamps
    end
    add_column :people, :latest_efz_issued_on, :date
  end
end
