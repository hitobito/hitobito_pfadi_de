# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module Sheet
  class RoleList < Base
    self.parent_sheet = Sheet::Group

    def current_parent_nav_path
      view.group_roles_path(parent_sheet.entry)
    end
  end
end
