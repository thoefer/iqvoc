# encoding: UTF-8

# Copyright 2011 innoQ Deutschland GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Iqvoc
  module RDFAPI
    autoload :NTParser, 'iqvoc/rdfapi/nt_parser'

    FIRST_LEVEL_OBJECT_CLASSES  = [Iqvoc::Concept.base_class, Iqvoc::Collection.base_class]
    SECOND_LEVEL_OBJECT_CLASSES = Iqvoc::Concept.labeling_classes.keys +
                                  Iqvoc::Concept.note_classes +
                                  Iqvoc::Concept.relation_classes +
                                  Iqvoc::Concept.match_classes +
                                  Iqvoc::Collection.member_classes

    OBJECT_DICTIONARY = FIRST_LEVEL_OBJECT_CLASSES.inject({}) do |hash, klass|
      hash["#{klass.rdf_namespace}:#{klass.rdf_class}"] = klass
      hash
    end

    PREDICATE_DICTIONARY = SECOND_LEVEL_OBJECT_CLASSES.inject({}) do |hash, klass|
      hash["#{klass.rdf_namespace}:#{klass.rdf_predicate}"] = klass
      hash
    end

    def self.devour(rdf_subject_or_string, rdf_predicate = nil, rdf_object = nil)
      if rdf_predicate.nil? and rdf_object.nil?
        # we have a single string to parse and interpret
        rdf_subject, rdf_predicate, rdf_object = rdf_subject_or_string.split(/\s+/, 3)
      else
        rdf_subject = rdf_subject_or_string
      end

      if rdf_subject.is_a? String
        rdf_subject = rdf_subject.sub(/^:/, '') # strip default namespace
      end

      if rdf_object.is_a? String
        rdf_object = rdf_object.sub(/^:/, '') # strip default namespace
      end

      case rdf_predicate
      when 'a', 'rdf:type'
        case rdf_object
        when String
          target = OBJECT_DICTIONARY[rdf_object] || rdf_object.constantize
        else
          target = rdf_object
        end
        target.find_or_initialize_by_origin(rdf_subject)
      when String
        # dictionary lookup
        target = PREDICATE_DICTIONARY[rdf_predicate] || rdf_predicate.constantize
        target.build_from_rdf(rdf_subject, target, rdf_object)
      else # is a class
        rdf_predicate.build_from_rdf(rdf_subject, rdf_predicate, rdf_object)
      end
    end

    def self.slurp(io_or_string)
      case io_or_string
      when String
        stream = StringIO.new io_or_string
      when IO
        stream = io_or_string
      else
        raise "I'd like an IO or a String, please."
      end

      stream.each_line do |line|
        self.devour(line.strip).save
      end
    end

    def self.parse_nt(str_or_io, default_namespace_url)
      parser = if str_or_io.is_a? IO
        NTParser.new str_or_io, default_namespace_url
      else
        NTParser.new StringIO.new(str_or_io), default_namespace_url
      end

      parser.each_valid_triple do |*triple|
        if block_given?
          yield *triple
        else
          self.devour(*triple).save
        end
      end
    end

  end
end
