# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields do
  describe ".version" do
    it "is a semantic version string" do
      expect(described_class.version).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end

  describe ".decidim_version" do
    it "declares a decidim dependency requirement" do
      expect(described_class.decidim_version).to include("0.29")
    end
  end
end
