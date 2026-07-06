# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::FormDefinition do
  let(:handler_name) { "extended_data" }

  let(:form_class) do
    Class.new do
      class << self
        attr_reader :attributes, :validations

        def attribute(name, type)
          (@attributes ||= {})[name] = type
        end

        def validates(name, **validations)
          (@validations ||= []) << { name:, validations: }
        end
      end

      def initialize(organization: nil)
        @current_organization = organization
        @data = {}
      end

      attr_reader :current_organization

      def []=(key, value)
        @data[key] = value
      end

      def [](key)
        @data[key]
      end

      def active_custom_field_names
        org = current_organization
        return [] unless org

        RegistrationFields.active_registration_fields(org).map(&:name)
      end
    end
  end

  it "adds configured custom fields at include-time" do
    with_customizations do
      register_test_customization(:default) do |customization|
        customization.registration_fields { |set| set.add_field(:foo, type: :text, required: true) }
      end

      klass = Class.new(form_class) do
        include Decidim::CustomUserFields::FormDefinition
      end

      expect(klass.attributes).to include(foo: String)
      expect(klass.validations).not_to be_empty
    end
  end

  it "maps model extended_data into the form for active fields only" do
    with_customizations do
      organization = create(:organization)
      register_test_customization(:default) do |customization|
        customization.registration_fields { |set| set.add_field(:foo, type: :text, required: true) }
      end
      enable_customization_for(organization, :default)

      klass = Class.new(form_class) do
        include Decidim::CustomUserFields::FormDefinition
      end

      model = Struct.new(:extended_data).new({ foo: "  bar " })
      form = klass.new(organization:)
      allow(form).to receive(:current_organization).and_return(organization)

      form.map_model(model)

      expect(form[:foo]).to eq("bar")
    end
  end

  it "ignores missing extended_data keys for active fields" do
    with_customizations do
      organization = create(:organization)
      register_test_customization(:default) do |customization|
        customization.registration_fields { |set| set.add_field(:foo, type: :text, required: true) }
      end
      enable_customization_for(organization, :default)

      klass = Class.new(form_class) do
        include Decidim::CustomUserFields::FormDefinition
      end

      model = Struct.new(:extended_data).new(nil)
      form = klass.new(organization:)
      allow(form).to receive(:current_organization).and_return(organization)

      expect { form.map_model(model) }.not_to raise_error
      expect(form[:foo]).to be_nil
    end
  end

  it "does not map fields from disabled customizations" do
    with_customizations do
      organization = create(:organization)
      register_test_customization(:default) do |customization|
        customization.registration_fields { |set| set.add_field(:foo, type: :text) }
      end
      register_test_customization(:other) do |customization|
        customization.registration_fields { |set| set.add_field(:bar, type: :text) }
      end
      enable_customization_for(organization, :default)

      klass = Class.new(form_class) do
        include Decidim::CustomUserFields::FormDefinition
      end

      model = Struct.new(:extended_data).new({ foo: "yes", bar: "no" })
      form = klass.new(organization:)
      allow(form).to receive(:current_organization).and_return(organization)

      form.map_model(model)

      expect(form[:foo]).to eq("yes")
      expect(form[:bar]).to be_nil
    end
  end
end
