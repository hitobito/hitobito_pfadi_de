# frozen_string_literal: true

#  Copyright (c) 2012-2025, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito_bdp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_bdp.

class Group::Bundesgeschaeftsstelle < ::Group
  ### ROLES

  class Bundesgeschaeftsfuehrung < ::Role
    self.permissions = [:layer_and_below_full, :admin, :contact_data, :finance]
    self.two_factor_authentication_enforced = true
    self.sgbviii_required = true
  end

  class MitgliederverwaltungBund < ::Role
    self.permissions = [:layer_and_below_full, :admin, :contact_data, :finance]
    self.two_factor_authentication_enforced = true
    self.sgbviii_required = true
  end

  class HauptamtlichSachbearbeitung < ::Role
    self.permissions = [:layer_and_below_full, :contact_data]
    self.two_factor_authentication_enforced = true
    self.sgbviii_required = true
  end

  class HauptamtlichReferent < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
    self.two_factor_authentication_enforced = true
    self.sgbviii_required = true
  end

  class Hauptamtlich < ::Role
    self.permissions = [:contact_data]
    self.two_factor_authentication_enforced = true
    self.sgbviii_required = true
  end

  roles Bundesgeschaeftsfuehrung,
    MitgliederverwaltungBund,
    HauptamtlichSachbearbeitung,
    HauptamtlichReferent,
    Hauptamtlich
end
