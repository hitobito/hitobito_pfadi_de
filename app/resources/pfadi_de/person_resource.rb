# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::PersonResource
  extend ActiveSupport::Concern

  prepended do
    attribute :pronoun, :string
    attribute :entry_date, :date, writable: false do
      @object.entry_date
    end
    attribute :exit_date, :date
    attribute :bank_account_owner, :string
    attribute :iban, :string
    attribute :bic, :string
    attribute :bank_name, :string
    attribute :payment_method, :string
    attribute :consent_data_retention, :boolean
  end
end
