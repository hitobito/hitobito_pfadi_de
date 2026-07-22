# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class People::FeeRatesQuery
  attr_reader :period_start_on, :period_end_on, :target_layer_id, :ancestor_groups

  def initialize(period_start_on:, period_end_on:, target_layer_id:, ancestor_groups:)
    @period_start_on = period_start_on
    @period_end_on = period_end_on
    @target_layer_id = target_layer_id
    @ancestor_groups = ancestor_groups
  end

  def applicable_fee_rate_id
    # For each person...
    Person.joins(roles_unscoped: :fee_kind)
      # find the single relevant membership role in the period
      .merge(membership_role)
      # traverse the fee kind hierarchy up to the layer which sends the invoice
      .merge(target_fee_kind_join)
      # select the appropriate fee rate for the person
      .merge(FeeKind.joins_applicable_fee_rate(period_start_on:, period_end_on:,
        fee_kinds_table_name: "target_fee_kind"))
      # find all relevant groups in which this person's membership is nested
      .merge(ancestor_group_join)
      # return the fee rate id for each person and recipient group
      .reselect("DISTINCT ON (ancestor.id, people.id) " \
        "ancestor.id, people.id AS id, fee_rates.id AS fee_rate_id")
  end

  private

  def membership_role
    # Find all roles and their groups of the person
    Role.joins(:group)
      # only select a single role for each person
      .select("DISTINCT ON (people.id) roles.id AS role_id, roles.*")
      # only allow membership roles
      .where(type: Role.types_with_fee_kind.map(&:name))
      # only allow roles that are considered active
      .active(active_range)
      # prefer the oldest role of each person in each layer context, tiebreak by role id
      .order("ancestor.id", "people.id", :start_on, :id)
  end

  def active_range
    return period_end_on if FeatureGate.enabled?("membership_fees.only_active_people")
    period_start_on..period_end_on
  end

  def target_fee_kind_join
    # Consider the base fee kind and all its ancestors
    FeeKind.joins("INNER JOIN fee_kinds target_fee_kind ON " \
      "target_fee_kind.lft <= fee_kinds.lft AND target_fee_kind.rgt >= fee_kinds.rgt")
      # select the one on the layer which sends the invoice
      .where(target_fee_kind: {layer_id: target_layer_id})
  end

  def ancestor_group_join
    Group.joins(
      "INNER JOIN groups ancestor ON ancestor.lft <= groups.lft AND ancestor.rgt > groups.lft"
    ).where(ancestor: {id: ancestor_groups})
  end
end
