# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe "PfadiDe::Shippable" do
  [Invoice, InvoiceRun, Message::Letter].each do |klass|
    it "disables all shippable attributes on #{klass}" do
      expect(klass.shippable_attributes).to eq([])
    end

    it "reports #{klass} instances as not shippable for any attribute" do
      expect(klass.new.shippable?(:shipping_method)).to eq(false)
      expect(klass.new.shippable?(:pp_post)).to eq(false)
    end
  end
end
