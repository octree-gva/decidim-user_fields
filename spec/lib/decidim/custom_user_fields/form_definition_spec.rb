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

        def validates(name, validations, **options)
          (@validations ||= []) << { name:, validations:, options: }
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
    with_registration_field_sets do
      register_test_field_set(:default) { |set| set.add_field(:foo, type: :text, required: true) }

      klass = Class.new(form_class) do
        include Decidim::CustomUserFields::FormDefinition
      end

      expect(klass.attributes).to include(foo: String)
      expect(klass.validations).not_to be_empty
    end
  end

  it "maps model extended_data into the form" do
    with_registration_field_sets do
      register_test_field_set(:default) { |set| set.add_field(:foo, type: :text, required: true) }

      klass = Class.new(form_class) do
        include Decidim::CustomUserFields::FormDefinition
      end

      model = Struct.new(:extended_data).new({ foo: "  bar " })
      form = klass.new

      form.map_model(model)

      expect(form[:foo]).to eq("bar")
    end
  end
end
