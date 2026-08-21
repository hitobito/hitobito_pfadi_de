# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Person
  extend ActiveSupport::Concern

  PAYMENT_METHODS = %w[invoice debit].freeze

  # rubocop:disable Metrics/BlockLength
  prepended do
    Person::PUBLIC_ATTRS.push(:pronoun, :bank_account_owner, :iban, :bic,
      :bank_name, :payment_method)

    Person::INTERNAL_ATTRS.push(:last_entry_date_with_fee_kind,
      :should_recalculate_last_entry_date_with_fee_kind,
      :latest_efz_issued_on)
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

  # Date of the first membership role (Ordentliche or Foerdermitgliedschaft, in any group).
  # Nil if no such role exists or none of them has a start date.
  def entry_date
    membership_roles.where.not(start_on: nil).minimum(:start_on)
  end

  # Date of the last membership role (Ordentliche or Foerdermitgliedschaft, in any group)
  # that has ended. Nil if no such role exists or none of them has an end date.
  def exit_date
    membership_roles.where.not(end_on: nil).maximum(:end_on)
  end

  private

  def membership_roles
    roles.with_inactive.where(type: ::Role.official_membership_role_types.map(&:sti_name))
  end
end
