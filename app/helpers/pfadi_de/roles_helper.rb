# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe
  module RolesHelper
    def format_role_type(role) = role.class.model_name.human

    def link_action_change_fee_kind(role)
      label = t("roles.fee_kind_change_link")
      if can?(:edit, role)
        link_to(
          icon(:"money-bill-1-wave"),
          new_role_fee_kind_change_path(role),
          title: label,
          alt: label,
          disabled: can?(:edit, role)
        )
      else
        icon(:"money-bill-1-wave", style: "opacity: 0.5")
      end
    end
  end
end
