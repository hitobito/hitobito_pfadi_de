#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FeeKindsController do
  let(:person) { people(:admin) }

  let(:group) do
    Fabricate(Group::Stamm.sti_name, name: "Falken", parent: groups(:baden_wuerttemberg))
  end

  let(:fee_kind) do
    Fabricate(:fee_kind, layer: group, parent: fee_kinds(:baden_wuerttemberg_kind))
  end

  before do
    # Fabricate(Group::Stamm::Stammesmitgliederverwaltung.sti_name, person:, group:)
    Fabricate(Group::Stamm::Stammesschatzmeister.sti_name, person:, group:)

    sign_in(person)
  end

  it "GET#index does list fee kinds" do
    get :index, params: {group_id: group.id}
    expect(assigns(:fee_kinds)).to include(fee_kind)
  end

  it "POST#create creates a new fee kind" do
    expect do
      post :create, params: {
        group_id: group.id,
        fee_kind: {
          name: "Test Foo",
          layer_id: group.layer_group.id,
          parent_id: fee_kinds(:baden_wuerttemberg_kind)
        }
      }

      expect(assigns(:fee_kind)).to be_valid
      expect(flash[:notice]).to eq(
        "Beitragsart <i>Test Foo</i> wurde erfolgreich erstellt."
      )
    end.to change { FeeKind.count }.by 1
  end

  it "PUT#update updates fee kind" do
    expect do
      post :update,
        params: {group_id: group, id: fee_kind.id,
                 fee_kind: {name: "Updated Foo"}}
    end.to change { fee_kind.reload.name }
    expect(flash[:notice]).to eq "Beitragsart <i>Updated Foo</i> " \
                                 "wurde erfolgreich aktualisiert."
  end
end
