# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

namespace :fee_kinds do
  desc "Set initial FeeKind on Role where needed"
  task set_initial: [:environment] do
    scope = Role.with_inactive.where(type: types, fee_kind_id: nil)

    warn "Trying to set initial FeeKind on #{scope.count} Roles..."

    scope.find_each do |role|
      result = role.update(fee_kind: FeeKindChooser.new(role).default)
      $stderr.print result ? "." : "F"
    end
  end
end
