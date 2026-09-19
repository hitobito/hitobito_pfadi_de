# frozen_string_literal: true

#  Copyright (c) 2012-2025, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito_bdp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_bdp.

module PfadiDe::ServiceToken
  extend ActiveSupport::Concern

  def dynamic_user
    super.tap do |person|
      permissions = person.roles.first.permissions
      permissions << finance_permission if fee_kinds?
      permissions << :layer_and_below_efz << :delete_efz if efz_einsichtnahmen?
      permissions << :create_membership_roles if create_membership_roles?
    end
  end

  private

  def finance_permission
    permission.to_s.include?("_and_below_") ? :layer_and_below_finance : :finance
  end
end
