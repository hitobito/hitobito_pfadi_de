# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe
  module RolesHelper
    def format_role_type(role) = role.class.model_name.human

    def format_role_fee_kind(role)
      return if role.fee_kind.blank?
      link_to(role.fee_kind.to_s, group_fee_kind_path(role.group.layer_group_id, role.fee_kind))
    end

    def link_action_change_fee_kind(role)
      label = t("role.fee_kind_change_link")
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

    # Submits via Turbo, so the confirmation of dependent role changes opens as modal.
    def link_action_end_or_destroy(role)
      return super if role.class.provided_prerequisite_categories.empty?

      if role.ends_on_destroy?
        turbo_delete_role_link(role, icon(:"circle-stop", filled: true),
          t("roles.end.title"), t("roles.end.confirm"))
      else
        turbo_delete_role_link(role, icon(:"trash-alt", filled: false),
          ti(:"link.delete"), ti(:confirm_delete))
      end
    end

    private

    def turbo_delete_role_link(role, label, title, confirm)
      link_to(label, group_role_path(role.group, role),
        class: "action", title:, alt: title,
        data: {turbo_method: :delete, turbo_confirm: confirm})
    end
  end
end
