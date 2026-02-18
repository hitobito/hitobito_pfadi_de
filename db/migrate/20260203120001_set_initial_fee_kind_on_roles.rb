# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class SetInitialFeeKindOnRoles < ActiveRecord::Migration[8.0]
  def up
    types = Role.all_types.select(&:has_fee_kind).map(&:name)
    scope = Role.with_inactive.where(type: types, fee_kind_id: nil)

    say_with_time("Setting the initial FeeKind on Role where needed") do
      say("Handling #{scope.count} Roles", :subitem)

      scope.in_batches do |batch|
        batch.each do |role|
          role.update(fee_kind: FeeKindChooser.new(role).default)
        end

        $stderr.print "."
      end
      $stderr.puts
    end
  end

  def down
    say_with_time("Removing the initial FeeKind on Role") do
      Role.update_all(fee_kind_id: nil)
    end
  end
end
