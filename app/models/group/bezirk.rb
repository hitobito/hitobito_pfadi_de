# frozen_string_literal: true

#  Copyright (c) 2012-2025, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito_bdp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_bdp.

class Group::Bezirk < ::Group
  self.layer = true

  children Group::Stamm,
    Group::Bezirksgeschaeftsstelle,
    Group::GruppierungsspezifischesGremium,
    Group::HeimZeltplatzLiegenschaft

  ### ROLES

  class Bezirkssprecher < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
    self.two_factor_authentication_enforced = true
    self.sgbviii_required = true
  end

  class BezirkssprecherStv < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
    self.two_factor_authentication_enforced = true
    self.sgbviii_required = true
  end

  class Bezirksschatzmeister < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
    self.two_factor_authentication_enforced = true
    self.sgbviii_required = true
  end

  class BezirksschatzmeisterStv < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
    self.two_factor_authentication_enforced = true
    self.sgbviii_required = true
  end

  class Bezirksbeauftragt < ::Role
    self.permissions = []
    self.sgbviii_required = true
  end

  class ErfassungFuehrungszeugnis < ::Role
    self.permissions = [:group_and_below_efz]
    self.two_factor_authentication_enforced = true
    self.sgbviii_required = true
  end

  class Kassenpruefung < ::Role
    self.permissions = []
  end

  roles Bezirkssprecher,
    BezirkssprecherStv,
    Bezirksschatzmeister,
    BezirksschatzmeisterStv,
    Bezirksbeauftragt,
    ErfassungFuehrungszeugnis,
    Kassenpruefung
end
