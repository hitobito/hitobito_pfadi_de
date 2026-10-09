# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::RoleResource
  extend ActiveSupport::Concern

  prepended do
    attribute :fee_kind_id, :integer, writable: :on_create

    belongs_to :fee_kind, writable: false
  end

  def on_create
    context.action_name.to_sym == :create
  end

  private

  def authorize_destroy(model)
    super

    unless PfadiDe::MembershipRoleRestrictions.new(model, current_ability).destroyable?
      errors = Graphiti::Util::SimpleErrors.new({})
      errors.add(:base, :membership_destroy_period_expired,
        message: model.errors.generate_message(:base, :membership_destroy_period_expired,
          days: PfadiDe::MembershipRoleRestrictions.change_max_days))
      raise Graphiti::Errors::InvalidRequest, errors
    end
  end
end
