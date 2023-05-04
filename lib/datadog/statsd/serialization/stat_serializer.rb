# frozen_string_literal: true

module Datadog
  class Statsd
    module Serialization
      class StatSerializer
        def initialize(prefix, global_tags: [])
          @prefix = prefix
          @prefix_str = prefix.to_s
          @tag_serializer = TagSerializer.new(global_tags)
        end

        def format(name, delta, type, tags: [], sample_rate: 1)
          name = formated_name(name)

          # we don't need sample rate, vitctoria metrics does not support it
          if tags_list = tag_serializer.format(tags)
            "#{@prefix_str}#{name};#{tags_list} #{delta}"
          else
            "#{@prefix_str}#{name} #{delta}"
          end
        end

        def global_tags
          tag_serializer.global_tags
        end

        private

        attr_reader :prefix
        attr_reader :tag_serializer

        def formated_name(name)
          if name.is_a?(String)
            # DEV: gsub is faster than dup.gsub!
            formated = name.gsub('::', '.')
          else
            formated = name.to_s
            formated.gsub!('::', '.')
          end

          formated.tr!(':|@', '_')
          formated
        end
      end
    end
  end
end
