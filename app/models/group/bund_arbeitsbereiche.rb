# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito_bdp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_bdp.

class Group::BundArbeitsbereiche < ::Group
  children Group::BundWoelflingsstufe,
    Group::BundPfadfinderstufe,
    Group::BundRangerRoverstufe,
    Group::BundStufen,
    Group::BundErwachsenenarbeit,
    Group::BundAusbildung,
    Group::BundInternationales,
    Group::BundIntakt,
    Group::BundOeffentlichkeitsarbeitMedien,
    Group::BundPolitischeBildungPolitikUndGesellschaft,
    Group::BundIt,
    Group::BundFindungskommission,
    Group::BundRainbow,
    Group::BundInklusion,
    Group::BundWachstumUndStaemme,
    Group::BundSonstiges
end
