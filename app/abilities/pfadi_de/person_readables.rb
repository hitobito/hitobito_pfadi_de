# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

# Adds :group_read_contact_data as a second, unidirectional way into the
# contact-data-visible lists that PersonReadables already builds for
# :contact_data. Unlike :contact_data, this does not require the target
# person to hold any particular permission herself - only that she shares a
# group with a holder of :group_read_contact_data.
module PfadiDe::PersonReadables
  extend ActiveSupport::Concern

  private

  def group_accessible_people
    super

    return unless group_read_contact_data_visible? && group_read_contact_data_in_this_group?

    can :index, Person, Person.only_public_data.joins(roles_join).where(groups: {id: group.id})
  end

  def accessible_conditions
    super.tap do |condition|
      if group_read_contact_data_visible? && group_read_contact_data_group_ids.present?
        condition.or(*group_read_contact_data_condition)
      end
    end
  end

  def has_group_based_conditions?
    super || (group_read_contact_data_visible? && group_read_contact_data_group_ids.present?)
  end

  # Excludes PersonFullReadables/PersonDetailsReadables (subclasses of PersonReadables),
  # mirroring how contact_data_visible? is turned off for them: :group_read_contact_data
  # only grants plain :show, never :show_full/:show_details.
  def group_read_contact_data_visible?
    instance_of?(PersonReadables)
  end

  def group_read_contact_data_group_ids
    permission_group_ids(:group_read_contact_data)
  end

  def group_read_contact_data_in_this_group?
    group_read_contact_data_group_ids.include?(group.id)
  end

  def group_read_contact_data_condition
    ["#{Group.quoted_table_name}.id IN (?)", group_read_contact_data_group_ids]
  end
end
