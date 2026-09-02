# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Person
  extend ActiveSupport::Concern

  PAYMENT_METHODS = %w[invoice debit].freeze

  MEMBERSHIP_APPLICATION_ATTRS = [
    :membership_application_reasons,
    :membership_application_statement_stamm,
    :membership_application_statement_lv,
    :membership_application_statement_bund,
    :membership_application_process_data,
    :membership_application_uuid
  ]

  # rubocop:disable Metrics/BlockLength
  prepended do
    Person::PUBLIC_ATTRS.push(:pronoun, :bank_account_owner, :iban, :bic,
      :bank_name, :payment_method)

    Person::INTERNAL_ATTRS.push(:last_entry_date_with_fee_kind,
      :should_recalculate_last_entry_date_with_fee_kind,
      :latest_efz_issued_on)
    Person::INTERNAL_ATTRS.concat(MEMBERSHIP_APPLICATION_ATTRS)

    Person::FILTER_ATTRS.push(:latest_efz_issued_on)

    paper_trail_options[:skip].concat([
      "last_entry_date_with_fee_kind",
      "should_recalculate_last_entry_date_with_fee_kind",
      "latest_efz_issued_on"
    ])

    has_many :efz_einsichtnahmen, dependent: :destroy

    include I18nSettable
    include I18nEnums

    i18n_enum :payment_method, PAYMENT_METHODS
    i18n_setter :payment_method, PAYMENT_METHODS

    Person::GENDERS.push("d")

    self.used_attributes -= [:company, :company_name]

    validates :iban, iban: true, on: :update, allow_blank: true
    validates :payment_method, inclusion: {in: PAYMENT_METHODS.map(&:to_s)}
  end
  # rubocop:enable Metrics/BlockLength

  def entry_date
    PfadiDe::LatestMembershipCalculator.new(self).entry_date
  end

  def exit_date
    PfadiDe::LatestMembershipCalculator.new(self).exit_date
  end
end
