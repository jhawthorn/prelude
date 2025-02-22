require_relative './preloader'
require_relative './method'

module Prelude
  module Preloadable
    extend ActiveSupport::Concern

    attr_writer :prelude_preloader

    class_methods do
      # Mapping of field name to block for resolving a given preloader
      def prelude_methods
        @prelude_methods ||= {}
      end

      # Define how to preload a given method
      def define_prelude(name, batch_size: nil, &blk)
        prelude_methods[name] = Prelude::Method.new(batch_size: batch_size, &blk)

        define_method(name) do |*args|
          unless @prelude_preloader
            @prelude_preloader = Preloader.new(self.class, [self])
          end

          @prelude_preloader.fetch(name, self, *args)
        end
      end
    end
  end
end
