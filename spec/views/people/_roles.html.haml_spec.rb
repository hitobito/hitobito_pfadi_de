# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe "people/_roles.html.haml" do
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  let(:person) { role.person }
  let(:role) { roles(:paying_member) }

  before do
    assign(:group, role.group)
    allow(view).to receive(:entry).and_return(person.decorate)
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  context "as paying member" do
    let(:current_user) { role.person }

    it "renders beitragsart icon without link" do
      puts dom.native
      expect(dom).to have_css ".fa-money-bill-1-wave", style: "opacity: 0.5"
    end

    it "renders beitragsart icon without link" do
      expect(dom).to have_css "strong", text: "Ordentliche Mitgliedschaft"
      expect(dom).to have_css ".fa-money-bill-1-wave", style: "opacity: 0.5"
      expect(dom).not_to have_link "Beitragsart ändern"
    end
  end

  context "as admin" do
    let(:current_user) { people(:admin) }

    it "renders beitragsart icon without link" do
      expect(dom).to have_css "strong", text: "Ordentliche Mitgliedschaft"
      expect(dom).to have_css ".fa-money-bill-1-wave"
      expect(dom).to have_link "Beitragsart ändern", href: new_role_fee_kind_change_path(role)
    end
  end
end
