# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe::TokenAbility
  extend ActiveSupport::Concern

  def initialize(token)
    return if token.nil?

    super
    can :create_membership_roles, Group, id: registerable_groups if token.create_membership_roles?
  end

  def registerable_groups
    registerable_groups_scope
      .active
      .where(type: ::Group::Mitglieder.sti_name)
      .pluck(:id)
  end
end
