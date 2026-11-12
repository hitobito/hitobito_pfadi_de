# frozen_string_literal: true

#  Copyright (c) 2012-2025, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito_bdp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_bdp.

class Group::HeimZeltplatzLiegenschaft < ::Group
  self.used_attributes += [
    :property_type,
    :property_owner,
    :property_facilities_sanitary,
    :property_facilities_water,
    :property_guests_interior,
    :property_campingarea,
    :rental_audience,
    :rental_public_listing
  ]

  i18n_enum :property_type,
    %w[campsite building building_with_campsite education_center other],
    i18n_prefix: "activerecord.attributes.group.property_types"
  i18n_enum :property_owner,
    %w[local_group support_association municipality other],
    i18n_prefix: "activerecord.attributes.group.property_owners"
  i18n_enum :rental_audience,
    %w[bdp_groups rdp public],
    i18n_prefix: "activerecord.attributes.group.rental_audiences"

  validates :property_type, presence: true

  ### ROLES

  class AnsprechpersonVermietung < ::Role
    self.permissions = []
  end

  class HeimHauswartung < ::Role
    self.permissions = []
  end

  class VorstandsmitgliedHausverein < ::Role
    self.permissions = []
  end

  roles AnsprechpersonVermietung,
    HeimHauswartung,
    VorstandsmitgliedHausverein
end
