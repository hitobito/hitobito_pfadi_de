# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require_relative "sippe"
require_relative "runde"
require_relative "meute"
require_relative "gilde"

Group::Gruppen.children Group::Meute,
  Group::Gilde,
  Group::Sippe,
  Group::Runde
