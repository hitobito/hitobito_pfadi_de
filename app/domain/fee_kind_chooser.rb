# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class FeeKindChooser
  def initialize(allow_restricted: false)
    @allow_restricted = allow_restricted
  end

  def default(role)
    return nil unless role.fee_kind_type?
    return role.fee_kind if valid?(role)

    possible_for_role(role).first
  end

  def possible_for_role(role)
    return FeeKind.none unless role.fee_kind_type?

    allowed_fee_kinds(layers: role.group.layer_group.hierarchy, role_type: role.type)
  end

  def possible_parents(layer)
    Role.types_with_fee_kind.flat_map do |role_type|
      allowed_fee_kinds(layers: layer.ancestors, role_type: role_type.name)
    end
  end

  private

  # Checks whether the pre-selected fee kind on a role is valid for that role.
  # This check is independent of the user's permissions or archival or rules about
  # present or absent parents or children. It just validates whether anyone ever
  # could have selected this fee kind for this role.
  def valid?(role)
    all_candidates(layers: role.group.layer_group.hierarchy, role_type: role.type)
      .reorder(nil).pluck(:id)
      .include?(role.fee_kind_id)
  end

  # Returns an ordered list of all fee kinds which fit the basic premises of the role:
  # The layer and the role type.
  def all_candidates(layers:, role_type:)
    root_fee_kinds = FeeKind.arel_table.alias("root_fee_kinds")

    FeeKind
      .where(layer: layers)
      .joins(:layer)
      .order(created_at: :asc)
      .joins(join_to_root_fee_kinds(root_fee_kinds))
      .where(root_fee_kinds[:role_type].eq(role_type))
      .distinct
  end

  def current_candidates(layers:, role_type:)
    all_candidates(layers:, role_type:).not_archived
  end

  # Applies the full list of conditions on when fee kinds may be selected.
  def allowed_fee_kinds(layers:, role_type:)
    candidates = current_candidates(layers:, role_type:)

    lft_of_lowest_non_empty_layer = candidates.joins(:layer).maximum("groups.lft")

    # remove fee kinds from layers higher than necessary
    result = candidates.joins(:layer).where(groups: {lft: lft_of_lowest_non_empty_layer})

    # Apply restricted filter
    @allow_restricted ? result : filter_restricted(result)
  end

  # Builds a JOIN condition to connect fee_kinds to their root fee_kinds using nested set
  #
  # Uses Arel (ActiveRecord's query builder) to create a SQL JOIN that finds the root
  # fee_kind for each fee_kind using the nested set lft/rgt columns.
  #
  # `root_alias` is the aliased Arel::Table for root fee_kinds
  def join_to_root_fee_kinds(root_alias)
    fee_kinds = FeeKind.arel_table

    # Build JOIN condition using nested set logic:
    # A fee_kind is a descendant of a root if:
    # - Its lft is >= root's lft (starts after or at root)
    # - Its rgt is <= root's rgt (ends before or at root)
    # - The root has no parent (parent_id IS NULL)
    join_condition = fee_kinds[:lft].gteq(root_alias[:lft])      # fee_kinds.lft >= root.lft
                                    .and(fee_kinds[:rgt].lteq(root_alias[:rgt]))               # AND fee_kinds.rgt <= root.rgt
                                    .and(root_alias[:parent_id].eq(nil))                       # AND root.parent_id IS NULL

    # Build the JOIN and convert to format ActiveRecord understands
    # .join() creates the JOIN, .on() adds the condition, .join_sources extracts for AR
    fee_kinds.join(root_alias).on(join_condition).join_sources
  end

  # Filters out restricted fee_kinds by joining to root and checking restricted flag
  def filter_restricted(relation)
    root_for_restricted = FeeKind.arel_table.alias("root_for_restricted")

    # Join to root fee_kinds and filter where root.restricted is false or NULL
    relation.joins(join_to_root_fee_kinds(root_for_restricted))
            .where(root_for_restricted[:restricted].eq(false)          # WHERE root.restricted = false
                                                   .or(root_for_restricted[:restricted].eq(nil)))           # OR root.restricted IS NULL
  end
end
