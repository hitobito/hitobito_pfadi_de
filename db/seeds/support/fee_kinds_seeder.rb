#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FeeKindsSeeder
  FEE_KIND_NAMES = [
    "Mitgliederbeitrag", "Sozialbeitrag", "Familienbeitrag",
    "Förderbeitrag", "Ehrenbeitrag", "Schnupperbeitrag",
    "Partnerbeitrag", "Seniorenbeitrag", "Jugendbeitrag",
    "Einstiegsgebühr", "Verwaltungspauschale", "Sonderumlage",
    "Projektbeitrag", "Aktivitätsgebühr", "Lagerbeitrag"
  ]

  def seed_fee_kinds
    Group.root.role_types.each do |role_type|
      root_fee_kind = FeeKind.seed_once(name: "Bundesbeitrag", role_type: role_type.sti_name, layer: Group.root).first

      Group.where(parent: Group.root, type: Group::Landesverband.sti_name).each do |group|
        landesverband_fee_kind = FeeKind.seed_once(name: "Landesbeitrag #{root_fee_kind.human_role_name}", parent: root_fee_kind, layer: group).first

        group.children.where(type: Group::Stamm.sti_name).each do |stamm|
          FeeKind.seed_once(name: FEE_KIND_NAMES.sample, parent: landesverband_fee_kind, layer: stamm)
          FeeKind.seed_once(name: FEE_KIND_NAMES.sample, parent: landesverband_fee_kind, layer: stamm)
          FeeKind.seed_once(name: FEE_KIND_NAMES.sample, parent: landesverband_fee_kind, layer: stamm)
        end
      end
    end
  end
end