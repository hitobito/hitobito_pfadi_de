#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FeeKindsSeeder
  FEE_KIND_NAMES = [
    "Mitgliederbeitrag", "Sozialbeitrag", "Familienbeitrag",
    "Förderbeitrag", "Ehrenbeitrag", "Schnupperbeitrag",
    "Partnerbeitrag", "Einstiegsgebühr", "Verwaltungspauschale",
    "Sonderumlage", "Projektbeitrag", "Aktivitätsgebühr"
  ]

  FEE_RATE_NAMES = [
    "Normal", "Reduziert", "Spezial", "Jugend", "Neumitglied"
  ]

  FEE_RATE_VALIDITY_DATES = [
    2.years.ago.beginning_of_year,
    1.year.ago.beginning_of_year,
    6.months.ago.beginning_of_month,
    1.day.ago,
    0.days.ago,
    6.months.from_now.beginning_of_month,
    1.year.from_now.beginning_of_year,
    2.years.from_now.beginning_of_year,
  ]

  def seed_fee_kinds
    role_types = Role.all_types.select(&:has_fee_kind)
    role_types.each do |role_type|
      root_fee_kind = FeeKind.seed_once(
        name: "Bundesbeitrag #{role_type.model_name.human}",
        role_type: role_type.sti_name,
        layer: Group.root,
        restricted: false
      ).first

      Group.where(parent: Group.root, type: Group::Landesverband.sti_name).each do |group|
        landesverband_fee_kind = FeeKind.seed_once(name: FEE_KIND_NAMES.sample, parent: root_fee_kind, layer: group).first

        group.children.where(type: Group::Stamm.sti_name).each do |stamm|
          FeeKind.seed_once(name: FEE_KIND_NAMES.sample, parent: landesverband_fee_kind, layer: stamm)
          FeeKind.seed_once(name: FEE_KIND_NAMES.sample, parent: landesverband_fee_kind, layer: stamm)
          FeeKind.seed_once(name: FEE_KIND_NAMES.sample, parent: landesverband_fee_kind, layer: stamm)
        end
      end
    end

    Role.with_inactive.where(type: role_types, fee_kind_id: nil).find_each do |role|
      role.update(fee_kind: FeeKindChooser.new(role).default)
    end

    FeeKind.find_each do |fee_kind|
      3.times do
        valid_from, valid_until = rand(2) > 0 ? [FEE_RATE_VALIDITY_DATES.sample, nil] : FEE_RATE_VALIDITY_DATES.sample(2).minmax
        FeeRate.seed(:fee_kind_id, :amount, :valid_from, :valid_until, {
          fee_kind_id: fee_kind.id,
          name: FEE_RATE_NAMES.sample,
          amount: rand(50),
          valid_from:,
          valid_until:,
          max_member_months: [nil, nil, 6, 12].sample,
          max_age: [nil, nil, 10, 18].sample
        })
      end
      FeeRate.seed(:fee_kind_id, :amount, :valid_from, :valid_until, {
        fee_kind_id: fee_kind.id,
        name: FEE_RATE_NAMES.sample,
        amount: rand(50),
        valid_from: FEE_RATE_VALIDITY_DATES.select(&:past?).sample,
        valid_until: nil,
        max_member_months: [nil, nil, 6, 12].sample,
        max_age: [nil, nil, 10, 18].sample
      })
    end
  end
end
