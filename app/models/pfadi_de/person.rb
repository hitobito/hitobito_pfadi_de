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

  # Date the person's current, uninterrupted chain of membership roles
  # (Ordentliche or Foerdermitgliedschaft, in any group) began. Roles chain
  # together as long as there is no day without a membership role between
  # one ending and the next starting; a real gap starts a new chain. E.g.
  # member 2006-2022, gap, member again since 2024: entry_date is in 2024,
  # not 2006. Nil if the person has never held a membership role with a
  # start date.
  def entry_date
    chain_start_on = chain_end_on = nil

    membership_roles.where.not(start_on: nil).order(:start_on, :id).each do |role|
      if chain_start_on.nil? || gap_before?(chain_end_on, role.start_on)
        chain_start_on = role.start_on
        chain_end_on = role.end_on
      else
        chain_end_on = merge_end_on(chain_end_on, role.end_on)
      end
    end

    chain_start_on
  end

  # Date of the last membership role (Ordentliche or Foerdermitgliedschaft, in any group)
  # that has ended. Nil if no such role exists, or if a membership role
  # without an end date is still ongoing (in which case older, already
  # ended membership roles are irrelevant).
  def exit_date
    return nil if membership_roles.active.where(end_on: nil).exists?

    membership_roles.maximum(:end_on)
  end

  private

  # True if there is at least one full day without a membership role
  # between the previous chain's end and the next role's start.
  def gap_before?(previous_end_on, next_start_on)
    previous_end_on && next_start_on > previous_end_on + 1.day
  end

  # Nil (open-ended) if either role is still ongoing, otherwise the later
  # of the two end dates.
  def merge_end_on(a, b)
    a && b && [a, b].max
  end

  def membership_roles
    roles.with_inactive.where(type: ::Role.primary_membership_role_types.map(&:sti_name))
  end
end
