#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FeeKindsController < CrudController
  self.nesting = Group

  self.permitted_attrs = [:name, :layer_id, :parent_id, :role_type]

  def destroy
    destroyed = run_callbacks(:destroy) { entry.archive } # this is archive instead of destroy
    set_failure_notice unless destroyed
    location = destroy_return_path(destroyed)
    respond_with(entry, success: destroyed, location: location)
  end

  private

  def list_entries
    super.includes([:parent]).includes(:parent)
  end
end
