# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

# == Schema Information
#
# Table name: period_invoice_template_items
#
#  id                         :integer          not null, primary key
#  name                       :string           not null
#  type                       :string           not null
#  cost_center                :string
#  account                    :string
#  dynamic_cost_parameters    :text
#  period_invoice_template_id :integer          not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  vat_rate                   :decimal(5, 2)
#
# Indexes
#
#  idx_on_period_invoice_template_id_ffb9250706  (period_invoice_template_id)
#

require "spec_helper"

describe PeriodInvoiceTemplate::FeeCalculationItem do
  let(:period_invoice_template) { Fabricate(:pfadi_de_period_invoice_template) }

  subject(:item) do
    described_class.new(
      id: 998877,
      period_invoice_template:,
      account: "1234",
      cost_center: "5678",
      name: "invoice item",
      dynamic_cost_parameters: {}
    )
  end

  context "to_invoice_item_for_groups" do
    let(:adler_fee_kind) {
      Fabricate(:fee_kind, layer: groups(:adler), name: "adler fee kind",
        parent: fee_kinds(:baden_wuerttemberg_kind))
    }
    let!(:adler_fee_rate) { Fabricate(:fee_rate, fee_kind: adler_fee_kind, name: "adler fee rate") }

    before do
      3.times do
        fee_kind = Fabricate(:fee_kind, layer: period_invoice_template.group)
        Fabricate(:fee_rate, fee_kind: fee_kind)
      end
    end

    it "generates one invoice item for each fee rate on the layer" do
      result = item.to_invoice_item_for_groups
      expect(result.length).to eq(3)
      result.each do |item|
        expect(item).to be_an_instance_of(Invoice::FeeCalculationItem)
        expect(item.dynamic_cost_parameters.keys).to include("fee_rate_id")
        expect(item.dynamic_cost_parameters["fee_rate_id"]).not_to eq adler_fee_rate.id
      end
    end
  end
end
