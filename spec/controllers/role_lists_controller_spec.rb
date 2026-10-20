# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe RoleListsController do
  render_views

  let(:user) { people(:stammesverwaltung) }
  let(:group) { groups(:adler_mitglieder) }
  let(:type) { Group::Mitglieder::OrdentlicheMitgliedschaft }
  let(:person) { Fabricate(:person) }
  let!(:role) do
    Fabricate(type.sti_name, person:, group:, start_on: Date.new(2025, 1, 1), created_at: 32.days.ago)
  end
  let!(:dependent) do
    Fabricate(Group::StammGruppePfadfinder::Mitglied.sti_name,
      person:, group: groups(:pfadfinder), start_on: Date.new(2025, 6, 1))
  end
  let(:dom) { Capybara::Node::Simple.new(response.body) }
  let(:types) { {type.sti_name => "1"} }

  around do |example|
    registry = PfadiDe::Role::PrerequisiteRole.registry.dup
    example.run
    PfadiDe::Role::PrerequisiteRole.registry.replace(registry)
  end

  before do
    Group::Mitglieder::OrdentlicheMitgliedschaft.provides_role :stamm_mitgliedschaft
    Group::StammGruppePfadfinder::Mitglied
      .depends_on_role :stamm_mitgliedschaft, scope: :layer, on_uncovered: :cascade
    sign_in(user)
  end

  def confirmation_page? = dom.has_css?("h1", text: "Abhängige Rollen anpassen")

  def reloaded_role = Role.with_inactive.find_by(id: role.id)

  describe "DELETE destroy" do
    def destroy(**params)
      delete :destroy, params: {group_id: group.id, ids: person.id.to_s, role: {types:}, **params}
    end

    it "asks for confirmation when dependent roles are shortened" do
      destroy

      expect(confirmation_page?).to be true
      expect(response).to have_http_status(:unprocessable_content)
      expect(dom).to have_css("td", text: "01.06.2025 – #{I18n.l(Date.yesterday)}")
      expect(dom).to have_field("role[types][#{type.sti_name}]", type: :hidden, with: "1")
      expect(dom).to have_field("ids", type: :hidden, with: person.id.to_s)
      expect(reloaded_role.end_on).to be_nil
      expect(dependent.reload.end_on).to be_nil
    end

    it "describes the removal instead of reporting success" do
      destroy

      expect(dom).to have_css("p", text: "Die ausgewählten Rollen werden entfernt.")
      expect(flash[:notice]).to be_nil
    end

    it "shows the confirmation within the people tab of the group" do
      destroy

      expect(dom).to have_css("nav.nav-left li.is-active", text: group.to_s)
      expect(dom).to have_css(".sheet.parent .nav-sub li.active", text: "Personen")
      expect(dom).to have_css(".sheet.current h1", text: "Abhängige Rollen anpassen")
    end

    it "shortens dependent roles when confirmed" do
      destroy(prerequisite_cascade_confirmed: true)

      expect(response).to redirect_to(group_people_path(group))
      expect(flash[:notice]).to eq "Eine Rolle wurde entfernt"
      expect(reloaded_role.end_on).to eq(Date.yesterday)
      expect(dependent.reload.end_on).to eq(Date.yesterday)
    end

    it "does not ask for confirmation for role types without dependent roles" do
      Fabricate(Group::Stamm::Stammesfuehrung.sti_name, person:, group: groups(:adler))

      delete :destroy, params: {group_id: groups(:adler).id, ids: person.id.to_s,
                                role: {types: {Group::Stamm::Stammesfuehrung.sti_name => "1"}}}

      expect(response).to redirect_to(group_people_path(groups(:adler)))
    end
  end

  describe "PUT update" do
    def move(new_type, **params)
      put :update, params: {
        group_id: group.id, ids: person.id.to_s,
        role: {types:, type: new_type.sti_name, group_id: group.id}, **params
      }
    end

    it "keeps dependent roles when the new role covers them" do
      Group::Mitglieder::Zweitmitgliedschaft.provides_role :stamm_mitgliedschaft

      move(Group::Mitglieder::Zweitmitgliedschaft)

      expect(response).to redirect_to(group_people_path(group))
      expect(reloaded_role.end_on).to eq(Date.yesterday)
      expect(dependent.reload.end_on).to be_nil
    end

    it "asks for confirmation when the new role does not cover the dependent roles" do
      move(Group::Mitglieder::Zweitmitgliedschaft)

      expect(confirmation_page?).to be true
      expect(dom).to have_css("p", text: "Die ausgewählten Rollen werden verschoben.")
      expect(flash[:notice]).to be_nil
      expect(reloaded_role.end_on).to be_nil
    end

    it "moves the roles when confirmed" do
      move(Group::Mitglieder::Zweitmitgliedschaft, prerequisite_cascade_confirmed: true)

      expect(flash[:notice]).to eq "Eine Rolle wurde verschoben"
      expect(dependent.reload.end_on).to eq(Date.yesterday)
    end
  end
end
