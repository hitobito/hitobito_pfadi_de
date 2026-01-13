#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FeeKindsController do
  let(:group) { Fabricate(Group::Bundesgeschaeftsstelle.sti_name, parent: groups(:root)) }
  let(:person) { people(:admin) }
  let(:fee_kind) {
    FeeKind.create!(layer: group, name: "Foo", parent: fee_kinds(:baden_wuerttemberg_kind))
  }

  before do
    sign_in(person)
    Fabricate(Group::Bundesgeschaeftsstelle::Bundesgeschaeftsfuehrung.sti_name, person:, group:)
  end

  it "GET#index does list fee kinds" do
    get :index, params: {group_id: group.id}
    expect(assigns(:fee_kinds)).to include(fee_kind)
  end

  it "POST#create creates a new fee kind" do
    expect do
      post :create, params: {
        group_id: Group.root.id,
        fee_kind: {
          name: "Test Foo",
          layer_id: groups(:root),
          role_type: "Cool::Role::Type"
        }
      }
    end.to change { FeeKind.count }.by 1
    expect(flash[:notice]).to eq "Beitragsart <i>Test Foo</i> wurde erfolgreich erstellt."
  end

  it "PUT#update updates fee kind" do
    expect do
      post :update,
        params: {group_id: group, id: fee_kind.id,
                 fee_kind: {name: "Updated Foo"}}
    end.to change { fee_kind.reload.name }
    expect(flash[:notice]).to eq "Beitragsart <i>Updated Foo</i> wurde erfolgreich aktualisiert."
  end
end
