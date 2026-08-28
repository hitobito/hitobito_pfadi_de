# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

# The Sitzanschrift (the main address of the group) is mandatory on Bundesebene,
# Landesverband and Stamm, but not on Bezirk and not on any subgroup.
#
# housenumber stays optional so that addresses without one (c/o, Postfach) can
# still be entered. country stays optional as well, a blank value falls back to
# Countries.default.
module PfadiDe::RequiredSitzanschrift
  extend ActiveSupport::Concern

  included do
    validates :street, :zip_code, :town, presence: true
  end
end
