# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe RolesController do
  let(:user) { people(:stammesverwaltung) }
  let(:today) { Date.new(2026, 4, 30) }
  let(:group) { groups(:adler_mitglieder) }
  let(:person) { Fabricate(:person) }
  let(:type) { Group::Mitglieder::OrdentlicheMitgliedschaft }
  let(:start_on) { Date.new(2025, 1, 1) }
  let(:end_on) { nil }
  let(:created_at) { today.noon - 33.days }
  let!(:role) { Fabricate(type.sti_name, person:, group:, start_on:, end_on:, created_at:) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before do
    travel_to(today.noon)
    sign_in(user)
  end

  def reloaded_role = Role.with_inactive.find(role.id)

  def update(attrs)
    put :update, params: {group_id: group.id, id: role.id, role: attrs}
  end

  describe "GET edit" do
    render_views

    context "for membership role created long ago" do
      it "disables restricted fields" do
        get :edit, params: {group_id: group.id, id: role.id}

        expect(dom).to have_field "role_start_on", disabled: true
        expect(dom).to have_field "role_end_on", disabled: false
        expect(dom).to have_select "role_type", disabled: true
        expect(dom).to have_field "role_label", disabled: false
      end
    end

    context "for recently created membership role" do
      let(:type) { Group::Mitglieder::Zweitmitgliedschaft }
      let(:created_at) { 32.days.ago }

      it "enables all fields" do
        get :edit, params: {group_id: group.id, id: role.id}

        expect(dom).to have_field "role_start_on", disabled: false
        expect(dom).to have_field "role_end_on", disabled: false
        expect(dom).to have_select "role_type", disabled: false
      end
    end
  end

  describe "PUT update" do
    context "start_on" do
      it "may not be changed on membership role created long ago" do
        expect do
          update(start_on: "2025-02-01")
        end.not_to change { reloaded_role.start_on }

        expect(response).to have_http_status(:unprocessable_content)
        expect(assigns(:role).errors.full_messages).to eq [
          "Von kann nur innerhalb von 32 Tagen nach dem Erfassen der Mitgliedschaft geändert werden"
        ]
      end

      it "may be changed on recently created membership role" do
        role.update_columns(created_at: 32.days.ago)

        expect do
          update(start_on: "2025-02-01")
        end.to change { reloaded_role.start_on }.to(Date.new(2025, 2, 1))
      end

      it "may be changed by admin" do
        sign_in(people(:admin))

        expect do
          update(start_on: "2025-02-01")
        end.to change { reloaded_role.start_on }.to(Date.new(2025, 2, 1))
      end

      it "may be changed on non-membership role" do
        role = Fabricate(Group::Stamm::Stammesbeauftragt.sti_name, group: groups(:adler),
          start_on:, created_at:)

        expect do
          put :update, params: {group_id: role.group_id, id: role.id, role: {start_on: "2025-02-01"}}
        end.to change { role.reload.start_on }.to(Date.new(2025, 2, 1))
      end
    end

    it "allows other changes on membership role created long ago" do
      expect do
        update(label: "Foo", start_on: start_on.to_s)
      end.to change { reloaded_role.label }.to("Foo")
    end

    context "end_on" do
      it "may be set to end_membership_max_days ago" do
        expect do
          update(end_on: (today - 32.days).to_s)
        end.to change { reloaded_role.end_on }.to(today - 32.days)
      end

      it "may not be set further in the past" do
        expect do
          update(end_on: (today - 33.days).to_s)
        end.not_to change { reloaded_role.end_on }

        expect(response).to have_http_status(:unprocessable_content)
        expect(assigns(:role).errors.full_messages).to eq [
          "Bis darf höchstens 32 Tage in der Vergangenheit liegen"
        ]
      end

      it "may be set further in the past by admin" do
        sign_in(people(:admin))

        expect do
          update(end_on: (today - 1.year).to_s)
        end.to change { reloaded_role.end_on }.to(today - 1.year)
      end
    end

    context "type" do
      def change_type
        update(type: Group::Mitglieder::Zweitmitgliedschaft.sti_name, group_id: group.id)
      end

      it "may not be changed on membership role created long ago" do
        expect { change_type }.not_to change { Role.with_inactive.count }

        expect(response).to have_http_status(:unprocessable_content)
        expect(reloaded_role.end_on).to be_nil
        expect(assigns(:role).errors.full_messages).to eq [
          "Gruppe und Rolle einer Mitgliedschaft können nur innerhalb von 32 Tagen nach dem " \
          "Erfassen geändert werden"
        ]
      end

      it "may be changed on recently created membership role" do
        role.update_columns(created_at: 32.days.ago)

        change_type

        expect(response).to be_redirect
        expect(person.roles.map(&:type)).to eq [Group::Mitglieder::Zweitmitgliedschaft.sti_name]
      end

      it "may be changed by admin" do
        sign_in(people(:admin))

        change_type

        expect(response).to be_redirect
        expect(person.roles.map(&:type)).to eq [Group::Mitglieder::Zweitmitgliedschaft.sti_name]
      end
    end
  end

  describe "DELETE destroy" do
    def destroy
      delete :destroy, params: {group_id: group.id, id: role.id}
    end

    it "ends membership role created long ago" do
      expect { destroy }.to change { reloaded_role.end_on }.to(today - 1.day)
    end

    context "with future membership role" do
      let(:start_on) { today + 1.month }

      it "does not hard destroy role created long ago" do
        expect { destroy }.not_to change { Role.with_inactive.count }

        expect(flash[:alert]).to eq "Eine Mitgliedschaft kann nur innerhalb von 32 Tagen nach " \
          "dem Erfassen gelöscht werden."
      end

      it "hard destroys recently created role" do
        role.update_columns(created_at: 32.days.ago)

        expect { destroy }.to change { Role.with_inactive.count }.by(-1)
      end

      it "hard destroys role created long ago as admin" do
        sign_in(people(:admin))

        expect { destroy }.to change { Role.with_inactive.count }.by(-1)
      end
    end
  end

  describe "with dependent roles" do
    render_views

    let(:dependent) do
      Fabricate(Group::StammGruppePfadfinder::Mitglied.sti_name,
        person:, group: groups(:pfadfinder), start_on: Date.new(2025, 6, 1))
    end

    around do |example|
      registry = PfadiDe::Role::PrerequisiteRole.registry.dup
      example.run
      PfadiDe::Role::PrerequisiteRole.registry.replace(registry)
    end

    before do
      [Group::Mitglieder::OrdentlicheMitgliedschaft,
        Group::Mitglieder::Foerdermitgliedschaft,
        Group::Mitglieder::Zweitmitgliedschaft].each do |type|
        type.provides_role :stamm_mitgliedschaft
      end
      Group::StammGruppePfadfinder::Mitglied
        .depends_on_role :stamm_mitgliedschaft, scope: :layer, on_uncovered: :cascade
      dependent
    end

    def confirmation_page? = dom.has_css?("h1", text: "Abhängige Rollen anpassen")

    context "PUT update" do
      it "asks for confirmation when dependent roles are shortened" do
        update(end_on: today + 1.month)

        expect(confirmation_page?).to be true
        expect(response).to have_http_status(:unprocessable_content)
        expect(dom).to have_css("td", text: "Adler / Pfadfinder*innen")
        expect(dom).to have_css("td", text: "01.06.2025 – #{I18n.l(today + 1.month)}")
        expect(dom).to have_field("role[end_on]", type: :hidden, with: (today + 1.month).to_s)
        expect(dom).to have_field("prerequisite_cascade_confirmed", type: :hidden, with: "true")
        expect(reloaded_role.end_on).to be_nil
        expect(dependent.reload.end_on).to be_nil
      end

      it "shortens dependent roles when confirmed" do
        put :update, params: {group_id: group.id, id: role.id, role: {end_on: today + 1.month},
                              prerequisite_cascade_confirmed: true}

        expect(response).to be_redirect
        expect(reloaded_role.end_on).to eq(today + 1.month)
        expect(dependent.reload.end_on).to eq(today + 1.month)
      end

      it "does not ask for confirmation when no dependent role is affected" do
        update(label: "Neu")

        expect(response).to be_redirect
        expect(reloaded_role.label).to eq "Neu"
      end

      it "does not ask for confirmation when the changes are invalid" do
        update(end_on: today - 1.year)

        expect(response).to have_http_status(:unprocessable_content)
        expect(confirmation_page?).to be false
      end

      it "keeps dependent roles when the membership type changes" do
        role.update_columns(created_at: 32.days.ago)

        update(type: Group::Mitglieder::Zweitmitgliedschaft.sti_name, group_id: group.id)

        expect(response).to be_redirect
        expect(reloaded_role.end_on).to eq(today - 1.day)
        expect(dependent.reload.end_on).to be_nil
      end

      context "moving the membership to another layer" do
        before { sign_in(people(:admin)) }

        def move_membership(**params)
          put :update, params: {
            group_id: group.id, id: role.id,
            role: {type: type.sti_name, group_id: groups(:mitglieder_28).id}, **params
          }
        end

        it "asks for confirmation" do
          expect { move_membership }.not_to change { Role.with_inactive.count }

          expect(confirmation_page?).to be true
          expect(dom).to have_css("td", text: "01.06.2025 – #{I18n.l(today - 1.day)}")
        end

        it "ends dependent roles when confirmed" do
          move_membership(prerequisite_cascade_confirmed: true)

          expect(response).to be_redirect
          expect(dependent.reload.end_on).to eq(today - 1.day)
        end
      end
    end

    context "DELETE destroy" do
      it "asks for confirmation" do
        delete :destroy, params: {group_id: group.id, id: role.id}

        expect(confirmation_page?).to be true
        expect(dom).to have_css("form[action='#{group_role_path(group, role)}'] " \
          "input[name=_method][value=delete]", visible: false)
        expect(reloaded_role.end_on).to be_nil
      end

      it "ends dependent roles when confirmed" do
        delete :destroy, params: {group_id: group.id, id: role.id, prerequisite_cascade_confirmed: true}

        expect(reloaded_role.end_on).to eq(today - 1.day)
        expect(dependent.reload.end_on).to eq(today - 1.day)
      end
    end
  end
end
