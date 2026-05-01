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
  attribute :start_on, :date, default: -> { Time.zone.today }

  validates :role, :start_on, presence: true
  validates_date :start_on, on_or_after: :role_start_on
  validates_date :start_on, before: :role_end_on, if: :role_end_on
  validates :fee_kind_id, inclusion: {in: ->(fee_kind_change) {
    fee_kind_change.role.possible_fee_kinds.map(&:id)
  }, allow_nil: true}
  validates :fee_kind_id, exclusion: {in: ->(fee_kind_change) {
    [nil, fee_kind_change.role.fee_kind_id]
  }, message: :already_active}

  delegate :start_on, :end_on, to: :role, prefix: true

  def initialize(role, attributes = {})
    @role = role
    super(attributes)
  end

  def new_fee_kind = @new_fee_kind ||= FeeKind.find(fee_kind_id)

  def to_restricted?
    new_fee_kind.restricted?
  end

  def save!
    raise ActiveRecord::RecordInvalid unless valid?

    Role.transaction do
      Role.create!(start_on:, fee_kind_id:, person:, type:, group:, end_on: role_end_on)
      role.update!(end_on: [start_on - 1.day, role.start_on].max)
    end
  end
end
