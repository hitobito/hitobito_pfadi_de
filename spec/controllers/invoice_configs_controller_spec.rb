#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe InvoiceConfigsController do
  let(:group) { groups(:root) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before do
    allow(Group::Bundesebene::MVAdmin).to receive(:permissions).and_return([:finance])
    sign_in(people(:admin))
  end

  describe "GET#edit" do
    render_views

    it "offers neither payment slip selection nor payment providers" do
      get :edit, params: {group_id: group.id, id: invoice_configs(:root).id}

      expect(dom).not_to have_select("invoice_config_payment_slip")
      expect(dom).not_to have_link("Zahlungsschnittstellen")
      expect(dom).not_to have_css("#payment_provider_configs")
    end
  end
end
