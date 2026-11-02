# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

# rechtsform dropped the "unbekannt" value in favor of the blank/_nil label.
class NullifyUnknownRechtsform < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE groups SET rechtsform = NULL WHERE rechtsform = 'unbekannt'"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
