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

  let(:user) { people(:bottom_leader) }
  let(:group) { groups(:pfadfinder) }
  let(:person) { people(:member) }

  let(:dropdown) do
    Dropdown::PeopleExport.new(
      self,
      user,
      {controller: "people", group_id: group.id}
    )
  end

  subject(:dom) { Capybara::Node::Simple.new(dropdown.to_s) }

  context "single person" do
    let(:assigns) { {"person" => people(:member)} }

    it "does not render link if person has no active role" do
      person.roles.update_all(end_on: Time.zone.yesterday)
      expect(dom).not_to have_link "eFZ Antrag"
    end

    it "has single item if person has single role" do
      roles(:paying_member).destroy!
      expect(person.roles).to have(1).item
      expect(dom).to have_link "eFZ Antrag", href: group_person_efz_antrag_path(group.id, person.id)
    end

    it "has dropdown with multiple items if person has mulitple roles" do
      expect(dom).to have_link "eFZ Antrag", href: "#"
      expect(dom).to have_link "Adler / Pfadfinder*innen", href: group_person_efz_antrag_path(group.id, person.id)
      expect(dom).to have_link "Adler / Gruppe",
        href: group_person_efz_antrag_path(groups(:adler_mitglieder).id, person.id)
    end
  end

  context "people" do
    let(:assigns) { {} }

    it "has no eFZ Antrag item" do
      expect(dom).not_to have_link "eFZ Antrag"
    end
  end
end
