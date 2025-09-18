# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class AddPaymentMethodToPeople < ActiveRecord::Migration[7.1]
  def change
    add_column :people, :payment_method, :string, null: false, default: "invoice"

    Person.reset_column_information
  end
end
