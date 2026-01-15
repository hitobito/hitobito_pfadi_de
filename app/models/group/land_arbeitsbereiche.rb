# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito_bdp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_bdp.

class Group::LandArbeitsbereiche < ::Group
  self.layer = true

  children Group::LandWoelflingsstufe,
    Group::LandPfadfinderstufe,
    Group::LandRangerRoverstufe,
    Group::LandStufen,
    Group::LandErwachsenenarbeit,
    Group::LandAusbildung,
    Group::LandInternationales,
    Group::LandIntakt,
    Group::LandOeffentlichkeitsarbeitMedien,
    Group::LandPolitischeBildungPolitikUndGesellschaft,
    Group::LandIt,
    Group::LandFindungskommission,
    Group::LandRainbow,
    Group::LandInklusion,
    Group::LandWachstumUndStaemme,
    Group::LandSonstiges
end
