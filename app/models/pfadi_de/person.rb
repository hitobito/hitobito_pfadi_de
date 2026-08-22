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

  # The layer group (Stamm/Land/Bund) in which this person is primarily
  # active. This is the group of their active legal membership role
  # (Ordentliche Mitgliedschaft or Foerdermitgliedschaft, as defined by the
  # BdP/DPSG bylaws); if they hold no such role, it falls back to the group
  # of their longest-ongoing role of any type. Labeled "Hauptgruppierung" in
  # the UI. This is independent of #primary_group (labeled
  # "Standardgruppe"/"Standardebene" in this wagon), which is a freely
  # chosen, purely UX-related setting.
  #
  # If several roles of the relevant kind are active at once, the one that
  # started earliest ("longest-ongoing") is considered authoritative.
  def membership_group_role
    earliest_role(membership_roles) || earliest_role(roles)
  end

  def membership_group
    membership_group_role&.group&.layer_group
  end

  private

  # The role that started earliest among those currently ongoing (already
  # started, not yet ended). Roles that have not started yet, or that have
  # already ended, are never considered, even if start_on lies further in
  # the past.
  def earliest_role(role_list)
    role_list
      .select { |role| ongoing?(role) }
      .min_by { |role| [role.start_on || Date::Infinity.new, role.id] }
  end

  def ongoing?(role)
    (role.start_on.nil? || role.start_on <= Date.current) &&
      (role.end_on.nil? || role.end_on >= Date.current)
  end

  def membership_roles
    roles.with_inactive.where(type: ::Role.official_membership_role_types.map(&:sti_name))
  end
end
