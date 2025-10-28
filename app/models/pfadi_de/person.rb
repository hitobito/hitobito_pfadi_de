# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Person
  extend ActiveSupport::Concern

  PAYMENT_METHODS = %w[invoice debit].freeze

  prepended do
    Person::PUBLIC_ATTRS.push(:pronoun, :exit_date, :bank_account_owner, :iban, :bic,
      :bank_name, :payment_method)

    include I18nSettable
    include I18nEnums

    i18n_enum :payment_method, PAYMENT_METHODS
    i18n_setter :payment_method, PAYMENT_METHODS

    Person::GENDERS.push("d")

    self.used_attributes -= [:company, :company_name]

    validates :iban, iban: true, on: :update, allow_blank: true
    validates :payment_method, inclusion: {in: PAYMENT_METHODS.map(&:to_s)}
  end

  def entry_date
    roles.with_inactive.first&.start_on
  end
end
