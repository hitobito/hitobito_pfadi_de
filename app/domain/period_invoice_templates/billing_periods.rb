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

  class BillingPeriods
    def initialize(start_on = nil, end_on = nil)
      @year = Time.zone.today.year
      @half_year = Settings.membership_fees.half_year_periods
      @current = Period.new(start_on, end_on) if [start_on, end_on].all?(&:present?)
    end

    def list # rubocop:todo Metrics/AbcSize
      @list ||= [
        @current,
        build_period(start_on - (offset * 3)),
        build_period(start_on - (offset * 2)),
        build_period(start_on - offset),
        build_period(start_on),
        build_period(start_on + offset),
        build_period(start_on + (offset * 2))
      ].compact_blank.sort
    end

    def current = (@current || list.find(&:current?)).to_s

    def find(string) = list.index_by(&:to_s).fetch(string)

    private

    attr_reader :year, :half_year, :today

    def start_on = start_mid_year? ? Date.new(year, 7, 1) : Date.new(year, 1, 1)

    def offset = half_year ? 6.months : 12.months

    def start_mid_year? = half_year && Date.new(year, 7, 1).past?

    def build_period(start_on) = Period.new(start_on, (start_on + offset) - 1.day)
  end
end
