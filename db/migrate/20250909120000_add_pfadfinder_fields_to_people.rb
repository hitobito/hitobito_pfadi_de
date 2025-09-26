# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class AddPfadfinderFieldsToPeople < ActiveRecord::Migration[7.1]
  def change
    add_column :people, :pronoun, :string
    add_column :people, :exit_date, :date
    add_column :people, :consent_data_retention, :boolean, null: false, default: false

    [:people, :groups].each do |contactable|
      add_column contactable, :bank_account_owner, :string
      add_column contactable, :iban, :string
      add_column contactable, :bic, :string
      add_column contactable, :bank_name, :string
    end

    Person.reset_column_information
    Group.reset_column_information
  end
end
