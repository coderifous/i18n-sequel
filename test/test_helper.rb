$KCODE = 'u' if RUBY_VERSION <= '1.9'

require 'bundler/setup'
require 'minitest/autorun'
require 'mocha/setup'
require 'test_declarative'

require 'i18n/sequel'
require 'i18n/tests'

begin
  require 'sequel'
  Sequel::Model.db
rescue LoadError => e
  puts "can't use Sequel backend because: #{e.message}"
rescue Sequel::Error
  case ENV['DB']
  when 'postgres'
    Sequel.postgres 'i18n_unittest', user: ENV['PG_USER'] || 'i18n', password: '', host: 'localhost'
  when 'mysql'
    Sequel.connect adapter: 'mysql2', database: 'i18n_unittest', username: 'root', password: '', host: 'localhost'
  else
    Sequel.sqlite
  end
  unless Sequel::Model.db.table_exists?(:translations)
    Sequel::Model.db.create_table :translations do |t|
      primary_key :id
      String :locale
      String :key
      String :value, text: true
      String :interpolations, text: true
      TrueClass :is_proc, null: false, default: false
    end
    Sequel::Model.db.add_index :translations, [:locale, :key], unique: true
  end

  require 'i18n/backend/sequel'
end

TEST_CASE = defined?(Minitest::Test) ? Minitest::Test : MiniTest::Unit::TestCase

class TEST_CASE
  alias :assert_raise :assert_raises
  alias :assert_not_equal :refute_equal

  def assert_nothing_raised(*args)
    yield
  end
end

class I18n::TestCase < TEST_CASE
  def setup
    I18n.enforce_available_locales = false
    I18n.available_locales = []
    I18n.locale = :en
    I18n.default_locale = :en
    I18n.load_path = []
    super
  end

  def teardown
    I18n.enforce_available_locales = false
    I18n.available_locales = []
    I18n.locale = :en
    I18n.default_locale = :en
    I18n.load_path = []
    I18n.backend = nil
    super
  end

  def translations
    I18n.backend.instance_variable_get(:@translations)
  end

  def store_translations(locale, data)
    I18n.backend.store_translations(locale, data)
  end

  def locales_dir
    File.dirname(__FILE__) + '/test_data/locales'
  end
end
