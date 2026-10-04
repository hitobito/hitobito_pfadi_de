# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

class CreateSepaMandates < ActiveRecord::Migration[8.0]
  def change
    create_table :sepa_mandates do |t|
      t.string :reference, limit: 35, null: false, index: {unique: true}
      t.string :evidence, null: false
      t.references :group, null: false, index: true
      t.references :person, null: false, index: true
      t.datetime :issued_at, null: false
      t.date :valid_from, null: false
      t.datetime :revoked_at
      t.references :creator, index: false
      t.references :revoker, index: false
      # version of the mandate text confirmed when issued online, see SepaMandate
      t.integer :mandate_text_version, limit: 2

      t.timestamps
    end
    add_index :sepa_mandates, [:person_id, :group_id], unique: true,
      where: "revoked_at IS NULL", name: "index_sepa_mandates_on_active_person_and_group"
  end
end
