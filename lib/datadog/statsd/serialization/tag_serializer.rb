# frozen_string_literal: true

module Datadog
  class Statsd
    module Serialization
      class TagSerializer
        def initialize(global_tags = [], env = ENV)
          @global_tags_as_hash = if global_tags.is_a?(Array)
            global_tags.map{|v| v.split(/=|:/).tap { |pair| pair[0] = pair[0].to_sym }}.to_h
          else
            global_tags || {}
          end
        end

        def format(message_tags)
          if !message_tags || message_tags.empty?
            tags = to_tags_list(@global_tags_as_hash)
            return tags.empty? ? nil : tags.join(';')
          end
          
          tags = if @global_tags_as_hash
            message_tags_as_hash = message_tags.is_a?(Hash) ? message_tags : message_tags.map{|v| v.split(/=|:/).tap { |pair| pair[0] = pair[0].to_sym }}.to_h

            # override global_tags by message_tags
            to_tags_list(@global_tags_as_hash.merge(message_tags_as_hash))
          else
            to_tags_list(message_tags)
          end
          
          tags.join(';')
        end

        def global_tags
          to_tags_list(@global_tags_as_hash)
        end

        private

        def to_tags_list(tags)
          case tags
          when Hash
            tags.map do |name, value|
              if value
                escape_tag_content("#{name}=#{value}")
              else
                escape_tag_content(name)
              end
            end
          when Array
            tags.map { |tag| escape_tag_content(tag) }
          else
            []
          end
        end

        def escape_tag_content(tag)
          tag.to_s.delete('|,')
        end
      end
    end
  end
end
