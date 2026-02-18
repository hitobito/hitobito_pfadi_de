#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class MigrateRoleTypes < ActiveRecord::Migration[8.0]
  def up
    Role.transaction do
      # Reset all role type namespaces to match their containing group type
      # This fixes the 500 errors, but roles in Group::*Arbeitsbereich groups, which inherit from a
      # common Group::BundArbeitsbereich group may not be searchable by type in people filters etc.
      Role.connection.execute("UPDATE roles r SET type = g.type || '::' || regexp_replace(r.type, '^.*::', '') FROM groups g WHERE r.group_id = g.id")

      # Reset all Arbeitsbereich role types to the proper superclass value
      [
        'Ausbildung',
        'Erwachsenenarbeit',
        'Findungskommission',
        'Inklusion',
        'Intakt',
        'IntaktMachtUndMiteinander',
        'IntaktPraeventionUndIntervention',
        'IntaktPsychischeGesundheit',
        'Internationales',
        'It',
        'OeffentlichkeitsarbeitMedien',
        'Pfadfinderstufe',
        'PolitischeBildungPolitikUndGesellschaft',
        'Rainbow',
        'RangerRoverstufe',
        'Sonstiges',
        'Stufen',
        'WachstumUndStaemme',
        'Woelflingsstufe',
      ].each do |ab_type|
        [
          'Bund',
          'Land',
          'Bezirk',
          'Stamm'
        ].each do |layer|
          Role.connection.execute("UPDATE roles r SET type = 'Group::#{layer}Arbeitsbereich::' || regexp_replace(r.type, '^.*::', '') FROM groups g WHERE r.type LIKE 'Group::#{layer}#{ab_type}::%' AND r.group_id = g.id")
        end
      end
    end
  end
end
