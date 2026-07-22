# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class Invoice::FeeCalculationItem < Invoice::PeriodItem
  validates :fee_rate_id, presence: true

  # Items with count 0 should not be inserted into the invoice.
  # We achieve this by marking the item as invalid if its count is 0.
  validates :count, numericality: {greater_than: 0}

  def fee_rate_id
    dynamic_cost_parameters[:fee_rate_id]
  end

  def fee_rate
    @fee_rate ||= FeeRate.find_by(id: fee_rate_id)
  end

  def unit_cost
    self[:unit_cost] ||= BigDecimal(fee_rate&.total_yearly_amount(period_start_on) || 0) /
      period_duration
  end

  def count
    self[:count] ||= scope.count("DISTINCT(people.id, ancestor.id)")
  end

  def period_duration
    FeatureGate.enabled?("membership_fees.half_year_periods") ? 2 : 1
  end

  private

  def subject_type
    Person
  end

  def base_scope
    Person.joins(roles_unscoped: :group)
  end

  def active_condition(start_on, end_on)
    # This would be redundant, since People::FeeRatesQuery already considers only active roles
    # Role.active(start_on..end_on)
    Role.with_inactive.all
  end

  def scope
    super
      .merge(fee_rate_condition)
      # If counting the people for multiple invoice recipients (ancestors) at the same time,
      # count occurrences for each ancestor separately.
      .select(:id, "ancestor.id AS ancestor_id").distinct
  end

  def fee_rate_condition
    # Only count people whose calculated fee rate matches the one this invoice item cares about
    subquery = People::FeeRatesQuery.new(
      period_start_on:, period_end_on:, target_layer_id: invoice.group_id, ancestor_groups: groups
    ).applicable_fee_rate_id

    Person.where("(ancestor.id, people.id, ?) IN (#{subquery.to_sql})", fee_rate_id)
  end
end
