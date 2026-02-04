# frozen_string_literal: true

#  Copyright (c) 2012-2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Role
  extend ActiveSupport::Concern

  included do
    # A valid and up-to-date Führungszeugnis is required for this role
    class_attribute :sgbviii_required
    self.sgbviii_required = false

    # this is a role that costs, so it needs a FeeKind to determine the cost/Fee
    class_attribute :has_fee_kind
    self.has_fee_kind = false

    belongs_to :fee_kind

    validate :validate_fee_kind
  end

  private

  def validate_fee_kind
    if self.class.has_fee_kind
      errors.add(:fee_kind, :blank) if fee_kind_id.nil?
    else
      errors.add(:fee_kind, :present) if fee_kind.present? # rubocop:disable Style/IfInsideElse match the condition above more closely
    end
  end
end
