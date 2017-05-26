require 'sequel'

module I18n
  module Backend
    # Sequel model used to store actual translations to the database.
    #
    # This model expects a table like the following to be already set up in
    # your the database:
    #
    #    Sequel::Model.db.create_table :translations do |t|
    #      primary_key :id
    #      String :locale
    #      String :key
    #      String :value, text: true
    #      String :interpolations, text: true
    #      TrueClass :is_proc, null: false, default: false
    #    end
    #    Sequel::Model.db.add_index :translations, [:locale, :key], unique: true
    #
    # This model supports to named scopes :locale and :lookup. The :locale
    # scope simply adds a condition for a given locale:
    #
    #   I18n::Backend::Sequel::Translation.locale(:en).all
    #   # => all translation records that belong to the :en locale
    #
    # The :lookup scope adds a condition for looking up all translations
    # that either start with the given keys (joined by an optionally given
    # separator or I18n.default_separator) or that exactly have this key.
    #
    #   # with translations present for :"foo.bar" and :"foo.baz"
    #   I18n::Backend::Sequel::Translation.lookup(:foo)
    #   # => an array with both translation records :"foo.bar" and :"foo.baz"
    #
    #   I18n::Backend::Sequel::Translation.lookup([:foo, :bar])
    #   I18n::Backend::Sequel::Translation.lookup(:"foo.bar")
    #   # => an array with the translation record :"foo.bar"
    #
    # When the StoreProcs module was mixed into this model then Procs will
    # be stored to the database as Ruby code and evaluated when :value is
    # called.
    #
    #   Translation = I18n::Backend::Sequel::Translation
    #   Translation.create \
    #     :locale => 'en'
    #     :key    => 'foo'
    #     :value  => lambda { |key, options| 'FOO' }
    #   Translation.find_by_locale_and_key('en', 'foo').value
    #   # => 'FOO'
    class Sequel
      class Translation < ::Sequel::Model

        TRUTHY_CHAR = "\001"
        FALSY_CHAR = "\002"

        plugin :serialization

        serialize_attributes :yaml, :value
        serialize_attributes :yaml, :interpolations

        # Sequel does not support default values for serialize_attributes
        def interpolations
          super || []
        end

        dataset_module do

          def locale(locale)
            where(locale: locale.to_s)
          end

          def find_by_key(key)
            where(key: key).first
          end

          def lookup(keys, *separator)
            keys = Array(keys).map! { |key| key.to_s }

            unless separator.empty?
              warn "[DEPRECATION] Giving a separator to Translation.lookup is deprecated. " <<
                "You can change the internal separator by overwriting FLATTEN_SEPARATOR."
            end

            namespace = "#{keys.last}#{I18n::Backend::Flatten::FLATTEN_SEPARATOR}%"
            where(key: keys).or(::Sequel.like(:key, namespace))
          end

          def available_locales
            distinct.select(:locale).all.map { |t| t.locale.to_sym }
          end

        end

        def interpolates?(key)
          self.interpolations.include?(key) if self.interpolations
        end

        def value
          value = super
          if is_proc
            Kernel.eval(value)
          elsif value == FALSY_CHAR
            false
          elsif value == TRUTHY_CHAR
            true
          else
            value
          end
        end

        def value=(value)
          if value === false
            value = FALSY_CHAR
          elsif value === true
            value = TRUTHY_CHAR
          end
          super(value)
        end

      end
    end
  end
end
