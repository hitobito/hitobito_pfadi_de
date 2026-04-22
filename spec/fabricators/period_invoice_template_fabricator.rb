#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

Fabricator(:pfadi_de_period_invoice_template, from: :period_invoice_template) do
  recipient_source {
    GroupsFilter.new(parent: Group.root, group_type: Group::Stamm.name, active_at: Time.zone.today)
  }
  before_create do |period_invoice_template|
    if period_invoice_template.items.empty?
      period_invoice_template.items.build(type: PeriodInvoiceTemplate::RoleCountItem.name,
        name: "Mitgliedsbeitrag", dynamic_cost_parameters: {
          unit_cost: "5", role_types: [Group::Mitglieder::OrdentlicheMitgliedschaft.name]
        })
    end
  end
end
