# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::DefinitionGuidance do
  describe ".unsupported_type_message" do
    it "suggests a close field type" do
      message = described_class.unsupported_type_message(:tex)

      expect(message).to match(/not supported/)
      expect(message).to match(/Did you mean\? text/)
    end

    it "lists supported types when nothing is close" do
      message = described_class.unsupported_type_message(:nope)

      expect(message).to match(/not supported/)
      expect(message).to include("supported:")
    end
  end

  describe "legacy and unknown DSL calls on CustomUserFields" do
    subject(:mod) { Decidim::CustomUserFields }

    it "raises a guided error for custom_fields" do
      expect { mod.custom_fields }.to raise_error(
        Decidim::CustomUserFields::Error,
        /register_customization|Customizations/
      )
    end

    it "raises a guided error for register_field_set" do
      expect { mod.register_field_set(:default) }.to raise_error(
        Decidim::CustomUserFields::Error,
        /register_customization/
      )
    end

    it "raises a guided error for configure { add_field }" do
      expect do
        mod.configure { |config| config.add_field(:code, type: :text) }
      end.to raise_error(Decidim::CustomUserFields::Error, /registration_fields/)
    end

    it "suggests register_customization for a typo" do
      expect { mod.register_customizaton(:community) }.to raise_error(
        Decidim::CustomUserFields::Error,
        /Did you mean\? register_customization/
      )
    end
  end

  describe "unknown DSL calls on Customizations::Builder" do
    it "suggests registration_fields for a typo" do
      customization = Decidim::CustomUserFields::Customizations::Customization.new(:demo)
      builder = Decidim::CustomUserFields::Customizations::Builder.new(customization)

      expect { builder.registration_field(&proc {}) }.to raise_error(
        Decidim::CustomUserFields::Error,
        /Did you mean\? registration_fields/
      )
    end
  end
end
