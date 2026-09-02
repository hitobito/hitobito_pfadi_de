# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class RemoveExitDateFromPeople < ActiveRecord::Migration[8.0]
  def change
    remove_column :people, :exit_date, :date
  end
end
