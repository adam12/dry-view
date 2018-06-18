require "dry/view/context"

RSpec.describe 'dry-view' do
  let(:vc_class) do
    Class.new(Dry::View::Controller) do
      configure do |config|
        config.paths = SPEC_ROOT.join('fixtures/templates')
        config.layout = 'app'
        config.template = 'users'
        config.default_format = :html
      end
    end
  end

  let(:context) do
    Class.new(Dry::View::Context) do
      def title
        'dry-view rocks!'
      end

      def assets
        -> input { "#{input}.jpg" }
      end
    end.new
  end

  it 'renders within a layout and makes the provided context available everywhere' do
    vc = vc_class.new

    users = [
      { name: 'Jane', email: 'jane@doe.org' },
      { name: 'Joe', email: 'joe@doe.org' }
    ]

    expect(vc.(context: context, locals: {users: users})).to eql(
      '<!DOCTYPE html><html><head><title>dry-view rocks!</title></head><body><div class="users"><table><tbody><tr><td>Jane</td><td>jane@doe.org</td></tr><tr><td>Joe</td><td>joe@doe.org</td></tr></tbody></table></div><img src="mindblown.jpg" /></body></html>'
    )
  end

  it 'renders without a layout' do
    vc = Class.new(vc_class) do
      configure do |config|
        config.layout = false
      end
    end.new

    users = [
      { name: 'Jane', email: 'jane@doe.org' },
      { name: 'Joe', email: 'joe@doe.org' }
    ]

    expect(vc.(context: context, locals: {users: users})).to eql(
      '<div class="users"><table><tbody><tr><td>Jane</td><td>jane@doe.org</td></tr><tr><td>Joe</td><td>joe@doe.org</td></tr></tbody></table></div><img src="mindblown.jpg" />'
    )
  end

  it 'renders a view without locals' do
    vc = Class.new(vc_class) do
      configure do |config|
        config.template = 'empty'
      end
    end.new

    expect(vc.(context: context, locals: {})).to eq(
      '<!DOCTYPE html><html><head><title>dry-view rocks!</title></head><body><p>This is a view with no locals.</p></body></html>'
    )
  end

  it 'renders a view with an alternative format and engine' do
    vc = vc_class.new

    users = [
      { name: 'Jane', email: 'jane@doe.org' },
      { name: 'Joe', email: 'joe@doe.org' }
    ]

    expect(vc.(context: context, locals: {users: users}, format: 'txt').strip).to eql(
      "# dry-view rocks!\n\n* Jane (jane@doe.org)\n* Joe (joe@doe.org)"
    )
  end

  it 'renders a view with a template on another view path' do
    vc = Class.new(vc_class) do
      configure do |config|
        config.paths = [SPEC_ROOT.join('fixtures/templates_override')] + Array(config.paths)
      end
    end.new

    users = [
      { name: 'Jane', email: 'jane@doe.org' },
      { name: 'Joe', email: 'joe@doe.org' }
    ]

    expect(vc.(context: context, locals: {users: users})).to eq(
      '<!DOCTYPE html><html><head><title>dry-view rocks!</title></head><body><h1>OVERRIDE</h1><div class="users"><table><tbody><tr><td>Jane</td><td>jane@doe.org</td></tr><tr><td>Joe</td><td>joe@doe.org</td></tr></tbody></table></div></body></html>'
    )
  end

  it 'renders a view that passes arguments to partials' do
    vc = Class.new(vc_class) do
      configure do |config|
        config.template = 'parts_with_args'
      end
    end.new

    users = [
      { name: 'Jane', email: 'jane@doe.org' },
      { name: 'Joe', email: 'joe@doe.org' }
    ]

    expect(vc.(context: context, locals: {users: users})).to eq(
      '<!DOCTYPE html><html><head><title>dry-view rocks!</title></head><body><div class="users"><div class="box"><h2>Nombre</h2>Jane</div><div class="box"><h2>Nombre</h2>Joe</div></div></body></html>'
    )
  end

  describe 'inheritance' do
    let(:parent_view) do
      klass = Class.new(Dry::View::Controller)

      klass.setting :paths, SPEC_ROOT.join('fixtures/templates')
      klass.setting :layout, 'app'
      klass.setting :formats, {html: :slim}

      klass
    end

    let(:child_view) do
      Class.new(parent_view) do
        configure do |config|
          config.template = 'tasks'
        end
      end
    end

    it 'renders within a parent class layout using provided context' do
      vc = child_view.new

      expect(vc.(context: context, locals: { tasks: [{ title: 'one' }, { title: 'two' }] })).to eql(
        '<!DOCTYPE html><html><head><title>dry-view rocks!</title></head><body><ol><li>one</li><li>two</li></ol></body></html>'
      )
    end
  end
end
