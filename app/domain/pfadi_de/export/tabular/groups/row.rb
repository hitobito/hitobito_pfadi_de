# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Export::Tabular::Groups::Row
  extend ActiveSupport::Concern

  def member_count
    mitglieder_group.people.distinct.count
  end

  def landesverband_id
    entry.landesverband&.name
  end

  private

  def mitglieder_group
    Group::Mitglieder.without_deleted.find_by(parent_id: entry.id) || entry
  end
end
