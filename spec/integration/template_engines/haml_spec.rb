require "haml"
require "dry/view/context"
require "dry/view/controller"

RSpec.describe "Template engines / haml" do
  let(:base_vc) {
    Class.new(Dry::View::Controller) do
      configure do |config|
        config.paths = FIXTURES_PATH.join("integration/template_engines/haml")
      end
    end
  }

  it "supports partials that yield" do
    vc = Class.new(base_vc) do
      configure do |config|
        config.template = "render_and_yield"
      end
    end.new

    expect(vc.().to_s.gsub(/\n\s*/m, "")).to eq "<wrapper>Yielded</wrapper>"
  end

  it "supports methods that yield" do
    context = Class.new(Dry::View::Context) do
      include Haml::Helpers

      def wrapper(&block)
        "<wrapper>#{yield}</wrapper>"
      end
    end.new

    vc = Class.new(base_vc) do
      configure do |config|
        config.default_context = context
        config.template = "method_with_yield"
      end
    end.new

    expect(vc.().to_s.gsub(/\n\s*/m, "")).to eq "<wrapper>Yielded</wrapper>"
  end
end
