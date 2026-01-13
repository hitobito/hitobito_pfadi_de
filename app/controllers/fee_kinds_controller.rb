#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FeeKindsController < CrudController
  self.nesting = Group

  self.permitted_attrs = [:name, :layer_id, :parent_id, :role_type]
end
