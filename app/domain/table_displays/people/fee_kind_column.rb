# frozen_string_literal: true

#  Copyright (c) 2025-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module TableDisplays
  module People
    class FeeKindColumn < PublicColumn
      delegate :can?, to: :ability
      delegate :tag, to: :template

      def required_model_includes(_attr)
        {roles: :fee_kind}
      end

      def required_permission(_attr) = :show

      # not sortable
      def sort_by(_attr) = nil

      private

      def allowed_value_for(person, _)
        lines(person).join(", ")
      end

      def lines(person)
        person.roles.select(&:fee_kind).map do |role|
          can_view_fee_kind?(role) ? role.fee_kind.to_s : not_allowed
        end
      end

      # NOTE: fee_kind.restricted? triggers DB queries (through nested set)
      # there is no easy way to preload that data yet
      def can_view_fee_kind?(role)
        can?(:assign_restricted_fee_kinds, role) || !role.fee_kind.restricted?
      end

      def not_allowed = I18n.t("global.not_allowed")
    end
  end
end
