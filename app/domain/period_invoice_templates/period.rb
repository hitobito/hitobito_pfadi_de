#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.
#
module PeriodInvoiceTemplates
  class Period
    delegate :begin, :end, to: :range

    attr_reader :range

    def initialize(start_on, end_on)
      @range = Date.parse(start_on.to_s)..Date.parse(end_on.to_s)
    end

    def to_s = [I18n.l(range.begin), I18n.l(range.end)].join(" - ")

    def current? = range.cover?(Time.zone.today)

    def <=>(other) = range.begin <=> other.begin
  end
end
