#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FeeKind < ActiveRecord::Base
  belongs_to :layer, class_name: "Group"
  belongs_to :parent, class_name: "FeeKind", optional: true
  has_many :fee_rates, dependent: :destroy

  attr_readonly :parent_id, :role_type

  validates :name, presence: true

  validates :role_type, presence: true, if: :top_layer?
  validates :role_type, absence: true, unless: :top_layer?

  validates :parent, absence: true, if: :top_layer?
  validates :parent, presence: true, unless: :top_layer?
  validates :parent, inclusion: {in: ->(fee_kind) {
    fee_kind.possible_fee_kind_parents
  }}, on: :create, unless: :top_layer?
  validate :validate_restricted

  # Used for ability, we don't want to override the methods that check group permissions
  alias_method :group, :layer

  scope :not_archived, -> {
    where(archived_at: nil).or(where(archived_at: Time.zone.now..))
  }

  def archive
    touch(:archived_at)
  end

  def self.root_fee_kind_of(fee_kind)
    return fee_kind if fee_kind.parent_id.nil?

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
    archived_suffix = "(#{I18n.t(:"activerecord.attributes.fee_kind.archived")})" if archived_at?
    roles_suffix = "(#{human_role_name})" if format == :with_role_type

    [
      name,
      roles_suffix,
      archived_suffix
    ].compact.join(" ")
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
    FeeKindChooser.new(allow_restricted: true).possible_parents(layer)
  end

  def restricted?
    self.class.root_fee_kind_of(self).restricted
  end

  def applicable_fee_rate(person, period_start_on, period_end_on)
    reference_date = fee_rate_reference_date(person, period_start_on, period_end_on)
    reference_birthday = person.birthday || 100.years.ago.to_date

    age_condition = "(max_age IS NULL OR
      (:reference_date::date - make_interval(years => max_age))::date <= :reference_birthday)"
    months_condition = "(max_member_months IS NULL OR
      :period_end_on <= (:reference_date::date + make_interval(months => max_member_months))::date)"

    fee_rates
      .active(period_start_on)
      .where("#{age_condition} AND #{months_condition}",
        reference_date:, reference_birthday:, period_end_on:)
      .order("max_age ASC NULLS LAST, max_member_months ASC NULLS LAST, valid_from ASC")
      .first
  end

  private

  def fee_rate_reference_date(person, period_start_on, period_end_on)
    entry_date = person.last_entry_date_with_fee_kind
    if entry_date.present? && entry_date >= period_start_on && entry_date <= period_end_on
      entry_date
    else
      period_start_on
    end
  end

  def validate_restricted
    if top_layer?
      errors.add(:restricted, :blank) if restricted.nil?
    else
      errors.add(:restricted, :present) unless restricted.nil?
    end
  end
end
