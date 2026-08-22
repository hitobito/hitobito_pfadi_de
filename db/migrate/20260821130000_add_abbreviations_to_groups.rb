# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class AddAbbreviationsToGroups < ActiveRecord::Migration[7.1]
  def change
    # null: true (with default []) on purpose: `Group.validates_by_schema` auto-adds a
    # presence validator for NOT NULL columns, which would make this optional attribute
    # required. The model's writer always normalizes the value to an array, never nil.
    add_column :groups, :abbreviations, :string, array: true, default: []
  end
end
