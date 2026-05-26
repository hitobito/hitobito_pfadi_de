# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 2
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Dropdown::PeopleExport do
  include Rails.application.routes.url_helpers

  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:role) { roles(:member) }
  let(:group) { role.group }
  let(:user) { role.person }
  let(:dropdown) do
    Dropdown::PeopleExport.new(
      self,
      user,
      {controller: "people", group_id: group.id}
    )
  end

  let(:adler_mitglieder) { groups(:adler_mitglieder) }

  subject(:dom) { Capybara::Node::Simple.new(dropdown.to_s) }

  it "does not render link if user has no active role" do
    role.person.roles.update_all(end_on: Time.zone.yesterday)
    expect(dom).not_to have_link "eFZ Antrag"
  end

  it "has single item if user has single role" do
    roles(:paying_member).destroy!
    expect(dom).to have_link "eFZ Antrag", href: group_person_efz_antrag_path(group.id, user.id)
  end

  it "has dropdown with multiple items if user has mulitple roles" do
    expect(dom).to have_link "eFZ Antrag", href: "#"
    expect(dom).to have_link "Adler / Pfadfinder*innen", href: group_person_efz_antrag_path(group.id, user.id)
    expect(dom).to have_link "Adler / Gruppe", href: group_person_efz_antrag_path(adler_mitglieder.id, user.id)
  end
end
