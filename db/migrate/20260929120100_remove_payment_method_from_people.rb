# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

# The payment method is derived from the active SEPA mandates of a person.
class RemovePaymentMethodFromPeople < ActiveRecord::Migration[8.0]
  def change
    remove_column :people, :payment_method, :string, null: false, default: "invoice"
  end
end
