# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

# A SEPA direct debit mandate of a person (payer) for a layer group (creditor).
# Mandates are immutable except for their revocation. Per person and group,
# only one mandate may be active at a time.
#
# For mandates issued online, mandate_text_version (smallint) records which
# version of the mandate text was confirmed. The versioned texts are kept in the
# code, so their history is tracked by git.
class SepaMandate < ActiveRecord::Base
  REFERENCE_FORMAT = %r{\A[A-Za-z0-9+?/\-:().,']+\z}
  DEFAULT_EVIDENCE = "Hitobito-Gruppierung"
  REVOCABLE_ATTRS = %w[revoked_at revoker_id updated_at].freeze

  # transient attribute used for validation (user must check confirmation checkbox)
  attr_accessor :confirmation

  belongs_to :group
  belongs_to :person
  belongs_to :creator, class_name: "Person", optional: true
  belongs_to :revoker, class_name: "Person", optional: true

  scope :active, -> { where(revoked_at: nil) }
  scope :list, -> { order(revoked_at: :desc, issued_at: :desc) }

  before_validation :generate_reference, on: :create, if: -> { reference.blank? }
  before_validation :set_default_evidence, on: :create

  validates_by_schema
  validates :reference, format: {with: REFERENCE_FORMAT}, uniqueness: true
  validates :confirmation, acceptance: {allow_nil: false}, on: :create
  validate :assert_group_accepts_mandates, :assert_person_has_bank_account, on: :create
  validate :assert_only_revocation_changed, on: :update
  validates_datetime :revoked_at, on_or_before: -> { Time.current }, allow_nil: true

  before_create :revoke_active_mandates

  has_paper_trail meta: {main_id: ->(m) { m.person_id }, main_type: Person.sti_name}

  def to_s = reference.to_s

  def active? = revoked_at.nil?

  def status = active? ? :active : :revoked

  def status_label = I18n.t("activerecord.attributes.sepa_mandate.statuses.#{status}")

  def revoke!(revoker = nil)
    update!(revoked_at: Time.current, revoker:)
  end

  private

  def generate_reference
    return if group_id.blank? || person_id.blank?

    self.reference = loop do
      candidate = [group_id, person_id, SecureRandom.hex(2).upcase].join("-")
      break candidate unless SepaMandate.exists?(reference: candidate)
    end
  end

  def set_default_evidence
    self.evidence = DEFAULT_EVIDENCE if evidence.blank?
  end

  def assert_group_accepts_mandates
    return if group.nil?

    if !group.layer?
      errors.add(:group, :not_a_layer)
    elsif !group.sepa_mandates_enabled?
      errors.add(:group, :sepa_mandates_disabled)
    end
  end

  def assert_person_has_bank_account
    errors.add(:person, :bank_account_missing) if person && person.iban.blank?
  end

  def assert_only_revocation_changed
    if (changed - REVOCABLE_ATTRS).any? || revoked_at_was.present?
      errors.add(:base, :immutable)
    end
  end

  def revoke_active_mandates
    SepaMandate.active.where(person_id:, group_id:).find_each { |m| m.revoke!(creator) }
  end
end
