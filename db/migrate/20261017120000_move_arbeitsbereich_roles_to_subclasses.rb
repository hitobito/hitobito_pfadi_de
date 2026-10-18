#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class MoveArbeitsbereichRolesToSubclasses < ActiveRecord::Migration[8.0]
  LAYERS = %w[Bund Land Bezirk Stamm].freeze

  def up
    # Roles in Arbeitsbereich groups were stored with the type of the shared base group
    # (e.g. Group::BundArbeitsbereich::Beauftragt). Each group type now has its own roles, so
    # the role type is set to the type of the group it belongs to.
    LAYERS.each do |layer|
      execute <<~SQL.squish
        UPDATE roles r
        SET type = g.type || '::' || regexp_replace(r.type, '^.*::', '')
        FROM groups g
        WHERE r.group_id = g.id
          AND r.type LIKE 'Group::#{layer}Arbeitsbereich::%'
          AND g.type <> 'Group::#{layer}Arbeitsbereich'
      SQL
    end
  end

  def down
    LAYERS.each do |layer|
      execute <<~SQL.squish
        UPDATE roles r
        SET type = 'Group::#{layer}Arbeitsbereich::' || regexp_replace(r.type, '^.*::', '')
        FROM groups g
        WHERE r.group_id = g.id
          AND g.type IN (#{subclass_types(layer)})
          AND r.type LIKE g.type || '::%'
      SQL
    end
  end

  private

  def subclass_types(layer)
    Dir[File.expand_path("../../app/models/group/#{layer.downcase}_*.rb", __dir__)].filter_map do |file|
      name = "Group::#{File.basename(file, ".rb").camelize}"
      name if File.read(file).match?(/< Group::#{layer}Arbeitsbereich$/)
    end.map { |t| connection.quote(t) }.join(", ").presence || "''"
  end
end
