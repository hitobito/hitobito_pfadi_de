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

  include_context "with isolated prerequisite registry"

  before do
    Group::Mitglieder::OrdentlicheMitgliedschaft.provides_role :stamm_mitgliedschaft
    Group::StammGruppePfadfinder::Mitglied
      .depends_on_role :stamm_mitgliedschaft, scope: :layer, on_uncovered: :cascade
    sign_in(user)
  end

  def confirmation_modal
    template = Nokogiri::HTML(response.body).at_css("turbo-stream[target=modal-placeholder] template")
    template && Capybara::Node::Simple.new(template.inner_html)
  end

  def confirmation_modal? = confirmation_modal&.has_css?("#prerequisite-cascade-confirmation")

  def reloaded_role = Role.with_inactive.find_by(id: role.id)

  describe "DELETE destroy" do
    def destroy(format: :html, **params)
      delete :destroy, params: {group_id: group.id, ids: person.id.to_s, role: {types:}, **params},
        format:
    end

    it "asks for confirmation in a modal when dependent roles are shortened" do
      destroy(format: :turbo_stream)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.media_type).to eq "text/vnd.turbo-stream.html"
      expect(confirmation_modal?).to be true
      expect(confirmation_modal).to have_css("td", text: "01.06.2025 – #{I18n.l(Date.yesterday)}")
      expect(confirmation_modal).to have_field("role[types][#{type.sti_name}]", type: :hidden, with: "1")
      expect(confirmation_modal).to have_field("ids", type: :hidden, with: person.id.to_s)
      expect(reloaded_role.end_on).to be_nil
      expect(dependent.reload.end_on).to be_nil
    end

    it "describes the removal instead of reporting success" do
      destroy(format: :turbo_stream)

      expect(confirmation_modal).to have_css("p", text: "Die ausgewählten Rollen werden entfernt.")
      expect(flash[:notice]).to be_nil
    end

    it "rejects the removal without turbo when dependent roles are affected" do
      destroy

      expect(response).to have_http_status(:unprocessable_content)
      expect(reloaded_role.end_on).to be_nil
      expect(dependent.reload.end_on).to be_nil
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
    def move(new_type, format: :html, **params)
      put :update, params: {
        group_id: group.id, ids: person.id.to_s,
        role: {types:, type: new_type.sti_name, group_id: group.id}, **params
      }, format:
    end

    it "keeps dependent roles when the new role covers them" do
      Group::Mitglieder::Zweitmitgliedschaft.provides_role :stamm_mitgliedschaft

      move(Group::Mitglieder::Zweitmitgliedschaft)

      expect(response).to redirect_to(group_people_path(group))
      expect(reloaded_role.end_on).to eq(Date.yesterday)
      expect(dependent.reload.end_on).to be_nil
    end

    it "asks for confirmation in a modal when the new role does not cover the dependent roles" do
      move(Group::Mitglieder::Zweitmitgliedschaft, format: :turbo_stream)

      expect(confirmation_modal?).to be true
      expect(confirmation_modal).to have_css("p", text: "Die ausgewählten Rollen werden verschoben.")
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
