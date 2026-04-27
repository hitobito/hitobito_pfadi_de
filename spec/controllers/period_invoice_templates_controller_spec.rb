#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe PeriodInvoiceTemplatesController do
  let(:leader) { people(:admin) }
  let(:group) { groups(:root) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before do
    allow(Group::Bundesebene::MVAdmin).to receive(:permissions).and_return([:finance])
    sign_in(leader)
    travel_to(Time.zone.local(2027, 4, 25))
  end

  let(:items_attributes) {
    {
      "0": {
        name: "Invoice item",
        type: PeriodInvoiceTemplate::RoleCountItem.name,
        dynamic_cost_parameters: {
          unit_cost: 10,
          role_types: [Group::Bundesebene::MVAdmin.name]
        }
      }
    }
  }

  describe "GET#new" do
    render_views

    it "has Abrechnungsperiode with current value selected" do
      get :new, params: {group_id: group.id}
      expect(dom).to have_select "Abrechnungsperiode", selected: "01.01.2027 - 31.12.2027"
    end
  end

  describe "POST#create" do
    let(:model_params) {
      {
        name: "dummy",
        billing_period: "01.01.2026 - 31.12.2026",
        items_attributes:
      }
    }

    it "creates model with period" do
      expect do
        post :create, params: {group_id: group.id, period_invoice_template: model_params}
      end.to change { PeriodInvoiceTemplate.count }.by(1)

      template = PeriodInvoiceTemplate.last
      expect(template.start_on).to eq Date.new(2026, 1, 1)
      expect(template.end_on).to eq Date.new(2026, 12, 31)
    end
  end

  describe "GET#edit" do
    render_views

    let!(:period_template) {
      PeriodInvoiceTemplate.create!(
        group_id: group.id,
        name: "dummy",
        start_on: "01.01.2000",
        end_on: "31.12.2001",
        items_attributes:
      )
    }

    it "has Abrechnungsperiode with value set from model" do
      get :new, params: {group_id: group.id, id: period_template.id}
      expect(dom).to have_select "Abrechnungsperiode", selected: "01.01.2000 - 31.12.2001"
    end
  end

  describe "PUT#update" do
    let!(:period_template) {
      PeriodInvoiceTemplate.create!(
        group_id: group.id,
        name: "dummy",
        start_on: "01.01.2000",
        end_on: "31.12.2001",
        items_attributes:
      )
    }

    let(:model_params) {
      {
        name: "dummy",
        billing_period: "01.01.2026 - 31.12.2026",
        items_attributes:
      }
    }

    it "updates current value from form submit" do
      expect do
        put :update,
          params: {group_id: group.id, id: period_template.id,
                   period_invoice_template: model_params}
      end.to change { period_template.reload.start_on }.to(Date.new(2026, 1, 1))
        .and change { period_template.end_on }.to(Date.new(2026, 12, 31))
    end
  end
end
