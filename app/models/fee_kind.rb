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

  def not_archived?
    archived_at.nil? || archived_at > Time.zone.now
  end

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

  # Returns a relation for the most appropriate FeeRate for each person during a billing period.
  # The people table must be joined BEFORE calling this method.
  # A custom name for the people table can be provided (e.g. when using an alias).
  #
  # Filters FeeRates by:
  # - Active status (valid on period_start_on)
  # - Age constraint (person is young enough for max_age)
  # - Membership duration constraint (membership fits within max_member_months)
  #
  # Prioritizes rates in order:
  # 1. Age-restricted rates (lower max_age first)
  # 2. Duration-restricted rates (lower max_member_months first)
  # 3. Older rates (lower valid_from first)
  def applicable_fee_rate_condition(period_start_on, period_end_on, people_table_name: "people")
    reference_date_sql = fee_rate_reference_date_sql(
      people_table_name, period_start_on, period_end_on
    )
    age_condition = fee_rate_age_condition_sql(people_table_name, reference_date_sql)
    months_condition = fee_rate_months_condition_sql(reference_date_sql, period_end_on)

    build_fee_rate_query(period_start_on, people_table_name, age_condition, months_condition)
  end

  private

  # Builds the FeeRate query with DISTINCT ON to get one rate per person
  def build_fee_rate_query(period_start_on, people_table_name, age_condition, months_condition)
    FeeRate
      .select(
        "DISTINCT ON (#{people_table_name}.id) " \
        "fee_rates.*, " \
        "#{people_table_name}.id AS person_id"
      )
      .active(period_start_on)
      .where(fee_kind_id: id)
      .where("#{age_condition} AND #{months_condition}")
      .order(
        "#{people_table_name}.id, " \
        "fee_rates.max_age ASC NULLS LAST, " \
        "fee_rates.max_member_months ASC NULLS LAST, " \
        "fee_rates.valid_from ASC"
      )
  end

  def quote(sql) = self.class.connection.quote(sql)

  # Calculates the reference date for age and membership duration checks.
  # Uses the person's entry date if it falls within the billing period,
  # otherwise falls back to the period start date.
  def fee_rate_reference_date_sql(people_table_name, period_start, period_end)
    <<~SQL
      (CASE
        WHEN #{people_table_name}.last_entry_date_with_fee_kind IS NOT NULL
             AND #{people_table_name}.last_entry_date_with_fee_kind >= #{quote(period_start)}
             AND #{people_table_name}.last_entry_date_with_fee_kind <= #{quote(period_end)}
        THEN #{people_table_name}.last_entry_date_with_fee_kind
        ELSE #{quote(period_start)}
      END)
    SQL
  end

  # Builds SQL condition to check if person is young enough for the fee rate's max_age constraint.
  # - Rates with max_age = NULL match any person (no age restriction)
  # - Otherwise, checks if person's birthday is after (reference_date - max_age years)
  # - People without birthdays are treated as 100 years old (excluded from age-restricted rates)
  def fee_rate_age_condition_sql(people_table_name, reference_date_sql)
    fallback_birthday = quote(FeeRate::BIRTHDAY_FALLBACK_YEARS.years.ago.to_date)

    <<~SQL
      (fee_rates.max_age IS NULL OR
       (#{reference_date_sql}::date - make_interval(years => fee_rates.max_age))::date
       <= COALESCE(#{people_table_name}.birthday, #{fallback_birthday})::date)
    SQL
  end

  # Builds SQL condition to check if membership duration fits the fee rate's max_member_months
  # constraint.
  # - Rates with max_member_months = NULL match any person (no duration restriction)
  # - Otherwise, checks if period_end_on is within (reference_date + max_member_months)
  # - This ensures only people who joined recently enough qualify for reduced rates
  def fee_rate_months_condition_sql(reference_date_sql, period_end)
    <<~SQL
      (fee_rates.max_member_months IS NULL OR
       #{quote(period_end)}::date <=
       (#{reference_date_sql}::date + make_interval(months => fee_rates.max_member_months))::date)
    SQL
  end

  def validate_restricted
    if top_layer?
      errors.add(:restricted, :blank) if restricted.nil?
    else
      errors.add(:restricted, :present) unless restricted.nil?
    end
  end
end
