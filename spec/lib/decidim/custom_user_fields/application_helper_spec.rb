# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::ApplicationHelper do
  it "is available for inclusion into forms" do
    expect(described_class).to be_a(Module)
  end
end
