# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

# The Swiss payment slip (Einzahlungsschein / QR-Rechnung) does not apply here and was
# restricted to "no_ps" in PfadiDe::InvoiceConfig (InvoiceConfig#payment_slips). Existing
# invoice configs were created before that and still carry the old "qr" default, so they
# need a one-time backfill. Already-issued invoices keep whatever payment_slip they were
# created with; only the group-level default is touched here.
class DisableInvoiceConfigPaymentSlip < ActiveRecord::Migration[8.0]
  def up
    say_with_time("Setting InvoiceConfig#payment_slip to no_ps where still qr") do
      InvoiceConfig.where.not(payment_slip: "no_ps").update_all(payment_slip: "no_ps")
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
