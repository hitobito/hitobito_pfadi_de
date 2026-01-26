# frozen_string_literal: true

#  Copyright (c) 2012-2025, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito_bdp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_bdp.

class Group::Bundesebene < ::Group
  self.layer = true
  self.event_types = [Event, Event::Course]

  children Group::Landesverband,
    Group::Bundesvorstand,
    Group::Bundesgeschaeftsstelle,
    Group::Ombudsrat,
    Group::Betrieb,
    Group::Bundesversammlung,
    Group::Projekte,
    Group::Kontakte,
    Group::Mitglieder,
    Group::BundArbeitsbereiche,
    Group::GruppierungsspezifischesGremium,
    Group::HeimZeltplatzLiegenschaft,
    Group::Foerderverein

  self.default_children = [
    Group::Bundesvorstand,
    Group::Ombudsrat,
    Group::BundArbeitsbereiche,
    Group::Projekte,
    Group::Mitglieder
  ]

  ### ROLES

  class MVAdmin < ::Role
    self.permissions = [:layer_and_below_full, :admin, :impersonation]
    self.two_factor_authentication_enforced = true
  end

  class ErfassungFuehrungszeugnis < ::Role
    self.permissions = [:layer_and_below_read, :group_and_below_efz]
    self.two_factor_authentication_enforced = true
    self.sgbviii_required = true
  end

  class Kassenpruefung < ::Role
    self.permissions = []
  end

  class Bundesmitarbeiter < ::Role
    self.permissions = []
    self.sgbviii_required = true
  end

  roles MVAdmin,
    ErfassungFuehrungszeugnis,
    Kassenpruefung,
    Bundesmitarbeiter
end
