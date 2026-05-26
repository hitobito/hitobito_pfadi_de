# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito_bdp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_bdp.

class Group::BezirkArbeitsbereiche < ::Group
  children Group::BezirkWoelflingsstufe,
    Group::BezirkPfadfinderstufe,
    Group::BezirkRangerRoverstufe,
    Group::BezirkStufen,
    Group::BezirkErwachsenenarbeit,
    Group::BezirkAusbildung,
    Group::BezirkInternationales,
    Group::BezirkIntakt,
    Group::BezirkOeffentlichkeitsarbeitMedien,
    Group::BezirkPolitischeBildungPolitikUndGesellschaft,
    Group::BezirkIt,
    Group::BezirkFindungskommission,
    Group::BezirkRainbow,
    Group::BezirkInklusion,
    Group::BezirkWachstumUndStaemme,
    Group::BezirkSonstiges
end
