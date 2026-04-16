# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class FeeRate < ApplicationRecord
  BIRTHDAY_FALLBACK_YEARS = 100

  validates_by_schema

  belongs_to :fee_kind
  has_one :layer, through: :fee_kind

  scope :list, -> { order("valid_from DESC, valid_until DESC NULLS FIRST") }
  scope :active, ->(reference_date = Date.current) {
    where(valid_from: ..reference_date)
      .merge(where(valid_until: nil).or(where(valid_until: reference_date..)))
  }
  scope :valid_today, -> { active }

  def group = layer

  def to_s = name

  def total_yearly_amount(date = Time.zone.today)
    return amount unless FeatureGate.enabled?("membership_fees.relative_fee_rates")

    fee_kind.ancestors.joins(:fee_rates).merge(FeeRate.active(date)).sum("fee_rates.amount") +
      amount
  end
end
