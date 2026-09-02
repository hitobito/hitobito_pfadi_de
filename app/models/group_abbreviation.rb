# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class GroupAbbreviation < ActiveRecord::Base
  belongs_to :group, inverse_of: :abbreviations

  before_validation :downcase_value

  validates_by_schema
  validate :assert_value_unique

  def to_s
    value
  end

  private

  # A DB query alone neither sees siblings which are newly built by the current nested
  # attributes assignment, nor knows that others are about to be destroyed by it.
  def assert_value_unique
    return if value.blank?

    errors.add(:value, :taken) if duplicate_sibling? || duplicate_in_db?
  end

  def siblings
    group&.abbreviations.to_a - [self]
  end

  def duplicate_sibling?
    siblings.reject(&:marked_for_destruction?)
      .any? { |sibling| sibling.value.to_s.downcase == value }
  end

  def duplicate_in_db?
    doomed_ids = siblings.select(&:marked_for_destruction?).map(&:id)
    GroupAbbreviation.where(value: value).where.not(id: [id, *doomed_ids].compact).exists?
  end

  def downcase_value
    self.value = value.to_s.strip.downcase.presence
  end
end
