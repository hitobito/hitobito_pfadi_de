#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FeeKind < ActiveRecord::Base
  belongs_to :layer, class_name: "Group"
  belongs_to :parent, class_name: "FeeKind", optional: true

  attr_readonly :parent_id, :role_type

  validates :name, presence: true

  validates :role_type, presence: true, if: -> { top_layer? }
  validates :role_type, absence: true, unless: -> { top_layer? }

  validates :parent, absence: true, if: -> { top_layer? }
  validates :parent, presence: true, unless: -> { top_layer? }
  validate :validate_unique_fee_parent_in_hierarchy, on: :create

  alias_method :group, :layer

  def self.root_fee_kind_of(fee_kind)
    return nil if fee_kind.parent_id.nil?

    query = <<-SQL
      WITH RECURSIVE root_fee_kind AS (
          SELECT *
          FROM fee_kinds
          WHERE id = #{fee_kind.parent_id}
        UNION ALL
          SELECT fee_kinds.*
          FROM fee_kinds
          JOIN root_fee_kind ON fee_kinds.id = root_fee_kind.parent_id
      )
      SELECT * FROM root_fee_kind WHERE parent_id IS NULL;
    SQL

    find_by_sql(query)&.first
  end

  def to_s(format = :default)
    (format == :with_role_type) ? "#{name} (#{human_role_name})" : name
  end

  def human_role_name
    (self[:role_type] || self.class.root_fee_kind_of(self)&.role_type).constantize
      .model_name
      .human
  end

  def top_layer?
    layer&.parent.nil?
  end

  def possible_fee_kind_parents
    FeeKind.where.not(id: used_fee_kind_parents.pluck("fee_kinds.parent_id"))
      .where(layer: layer.ancestors)
  end

  private

  def validate_unique_fee_parent_in_hierarchy
    return if parent_id.nil?

    unless possible_fee_kind_parents.exists?(id: parent_id)
      taken_name = used_fee_kind_parents
        .where(fee_kinds: {parent_id: parent_id})
        .pick("fee_kinds.name")

      errors.add(:parent_id, :parent_already_used_in_hierarchy, fee_kind_name: taken_name)
    end
  end

  def used_fee_kind_parents = layer.ancestors.joins(:fee_kinds)
end
