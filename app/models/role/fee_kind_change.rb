# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class Role::FeeKindChange
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_reader :role

  delegate :type, :person, :group, to: :role

  attribute :fee_kind_id, :integer
  attribute :start_on, :date

  validates :role, :start_on, presence: true
  validates_date :start_on, after: :role_start_on
  validates_date :start_on, before: :role_end_on, if: :role_end_on
  validate :assert_fee_kind_valid

  delegate :start_on, :end_on, to: :role, prefix: true

  def initialize(role, attributes = {})
    @role = role
    super(attributes)
  end

  def changes_restricted?
    FeeKind.where(restricted: true, id: [role.fee_kind_id, fee_kind_id]).exists?
  end

  def save!
    raise ActiveRecord::RecordInvalid unless valid?

    Role.transaction do
      Role.create!(start_on:, fee_kind_id:, person:, type:, group:, end_on: role_end_on)
      role.update!(end_on: start_on - 1.day)
    end
  end

  private

  def assert_fee_kind_valid
    possible_fee_kinds = role.possible_fee_kinds.map(&:id)
    if possible_fee_kinds.exclude?(fee_kind_id) || role.fee_kind_id == fee_kind_id
      errors.add(:fee_kind_id, :invalid)
    end
  end
end
