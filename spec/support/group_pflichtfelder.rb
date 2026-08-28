# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

# Sitzanschrift and Stammtyp are Pflichtfelder on Bundesebene, Landesverband and
# Stamm, so specs fabricating one of those have to supply them. The core group
# fabricator only sets a name.
#
# See PfadiDe::RequiredSitzanschrift and Group::Stamm.
module GroupPflichtfelder
  SITZANSCHRIFT = {
    street: "Hauptstraße",
    housenumber: "12",
    zip_code: "76133",
    town: "Karlsruhe"
  }.freeze

  STAMM = SITZANSCHRIFT.merge(stamm_typ: "stamm").freeze
end
