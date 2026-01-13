#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FeeKind < ActiveRecord::Base
  belongs_to :layer, class_name: "Group"
  belongs_to :parent, class_name: "FeeKind"

  attr_readonly :role_type

  validates :name, presence: true

  validates :role_type, presence: true, if: -> { top_layer? }
  validates :role_type, absence: true, unless: -> { top_layer? }

  validates :parent, presence: true, unless: -> { top_layer? }
  validate :validate_unique_fee_parent_in_hierarchy, on: :create

  alias_method :group, :layer

  def to_s
    name
  end

  def top_layer?
    return false if layer.nil?

    layer.parent.nil?
  end

  def possible_fee_kind_parents
    layer.ancestors.joins(:fee_kinds).select("fee_kinds.*")
  end

  private

  def validate_unique_fee_parent_in_hierarchy
    fee_kind_in_hierarchy = possible_fee_kind_parents.where(fee_kinds: {parent_id: parent_id})
      .pick("fee_kinds.name")

    if fee_kind_in_hierarchy.present?
      errors.add(:parent_id, :parent_already_used_in_hierarchy,
        fee_kind_name: fee_kind_in_hierarchy.to_s)
    end
  end
end
