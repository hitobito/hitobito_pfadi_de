# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito_bdp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_bdp.

class Group::Bezirksversammlung < ::Group
  self.static_name = true

  class Versammlungsleiter < ::Role
    self.permissions = []
    self.sgbviii_required = true
  end

  class Protokollführer < ::Role
    self.permissions = []
    self.sgbviii_required = true
  end

  class Techniker < ::Role
    self.permissions = []
    self.sgbviii_required = true
  end

  roles Versammlungsleiter,
    Protokollführer,
    Techniker
end
