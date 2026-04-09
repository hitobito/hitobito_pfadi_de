# frozen_string_literal: true

#  Copyright (c) 2012-2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Role
  extend ActiveSupport::Concern

  class_methods do
    # All role types that are fee-relevant (has_fee_kind = true).
    # Used for database queries and fee kind management.
    def types_with_fee_kind
      all_types.select(&:has_fee_kind)
    end
  end

  included do
    # A valid and up-to-date Führungszeugnis is required for this role
    class_attribute :sgbviii_required
    self.sgbviii_required = false

    # Use this to mark roles that cost (beitragsplichtige Rollen), so
    # they require a FeeKind to determine the cost/fee.
    # If has_fee_kind is true, you also need to mark the attribute
    # fee_kind_id as used, so that it is a permitted attribute.
    class_attribute :has_fee_kind
    self.has_fee_kind = false

    belongs_to :fee_kind

    validates :fee_kind, absence: true, unless: :fee_kind_type?
    validates :fee_kind, presence: true, if: :fee_kind_type?
    validates :fee_kind, inclusion: {in: ->(role) { role.possible_fee_kinds }}, if: :fee_kind_type?

    before_validation :ensure_fee_kind

    after_commit :mark_person_for_entry_date_recalculation
  end

  def possible_fee_kinds
    FeeKindChooser.new(allow_restricted: true).possible_for_role(self)
  end

  # Sets fee_kind to the default value. If a value is present already, the `FeeKindChooser`
  # will return the same value as long as it is a valid option for the current role type.
  def ensure_fee_kind
    self.fee_kind = FeeKindChooser.new.default(self)
  end

  def fee_kind_type?
    (type.safe_constantize || self.class).has_fee_kind
  end

  private

  def mark_person_for_entry_date_recalculation
    return unless fee_kind_type?

    person.update_attribute(:should_recalculate_last_entry_date_with_fee_kind, true)
  end
end
