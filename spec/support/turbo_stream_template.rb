# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module TurboStreamTemplate
  # Returns the content of the turbo stream for the target in the response.
  #
  # Turbo streams wrap their content in a <template>. Capybara empties template
  # elements when parsing HTML, as their content is not part of the document, so
  # the inner HTML is read with Nokogiri first.
  def turbo_stream_template(target)
    template = Nokogiri::HTML(response.body).at_css("turbo-stream[target=#{target}] template")
    template && Capybara::Node::Simple.new(template.inner_html)
  end
end

RSpec.configure do |config|
  config.include TurboStreamTemplate, type: :controller
end
