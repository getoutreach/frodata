# frozen_string_literal: true

require 'erb'
require 'uri'
require 'frodata/concerns/verbs'

module FrOData
  module Concerns
    module API
      extend FrOData::Concerns::Verbs

      # Public: Helper methods for performing arbitrary actions against the API using
      # various HTTP verbs.
      #
      # Examples
      #
      #   # Perform a get request
      #   client.get '/services/data/v24.0/sobjects'
      #   client.api_get 'sobjects'
      #
      #   # Perform a post request
      #   client.post '/services/data/v24.0/sobjects/Account', { ... }
      #   client.api_post 'sobjects/Account', { ... }
      #
      #   # Perform a put request
      #   client.put '/services/data/v24.0/sobjects/Account/001D000000INjVe', { ... }
      #   client.api_put 'sobjects/Account/001D000000INjVe', { ... }
      #
      #   # Perform a delete request
      #   client.delete '/services/data/v24.0/sobjects/Account/001D000000INjVe'
      #   client.api_delete 'sobjects/Account/001D000000INjVe'
      #
      # Returns the Faraday::Response.
      define_verbs :get, :post, :put, :delete, :patch, :head

      def metadata
        api_get("$metadata").body
      end

      # Public: Executs a SOQL query and returns the result.
      #
      # soql - A SOQL expression.
      #
      # Examples
      #
      #   # Find the names of all Accounts
      #   client.query('select Name from Account').map(&:Name)
      #   # => ['Foo Bar Inc.', 'Whizbang Corp']
      #
      # Returns a Restforce::Collection if Restforce.configuration.mashify is true.
      # Returns an Array of Hash for each record in the result if
      # Restforce.configuration.mashify is false.
      def query(soql)
        response = api_get 'query', q: soql
        mashify? ? response.body : response.body['records']
      end


      # Public: Perform a SOSL search
      #
      # sosl - A SOSL expression.
      #
      # Examples
      #
      #   # Find all occurrences of 'bar'
      #   client.search('FIND {bar}')
      #   # => #<Restforce::Collection >
      #
      #   # Find accounts match the term 'genepoint' and return the Name field
      #   client.search('FIND {genepoint} RETURNING Account (Name)').map(&:Name)
      #   # => ['GenePoint']
      #
      # Returns a Restforce::Collection if Restforce.configuration.mashify is true.
      # Returns an Array of Hash for each record in the result if
      # Restforce.configuration.mashify is false.
      def search(sosl)
        api_get('search', q: sosl).body
      end

      # Public: Insert a new record.
      #
      # entity_set - The set the entity belongs to
      # attrs   - Hash of attributes to set on the new record.
      #
      # Examples
      #
      #   # Add a new lead
      #   client.create('leads', {"firstname" =>'Bob'})
      #   # => '073ca9c8-2a41-e911-a81d-000d3a1d5a0b'
      #
      # Returns the String Guid of the newly created entity.
      # Returns false if something bad happens.
      def create(*args)
        create!(*args)
      rescue *exceptions
        false
      end
      alias insert create

      # Public: Insert a new record.
      #
      # entity_set - The set the entity belongs to
      # attrs   - Hash of attributes to set on the new record.
      #
      # Examples
      #
      #   # Add a new lead
      #   client.create!('leads', {"firstname" =>'Bob'})
      #   # => '073ca9c8-2a41-e911-a81d-000d3a1d5a0b'
      #
      # Returns the String Guid of the newly created entity.
      # Raises exceptions if an error is returned from Dynamics.
      def create!(entity_set, attrs)
        entity = service[entity_set].new_entity(attrs)
        url_chunk = to_url_chunk(entity)
        url = api_post(url_chunk, attrs).headers['odata-entityid']
        id = url.match(/\(.+\)/)[0]
      end
      alias insert! create!

      # Public: Update a record.
      #
      # entity_set - The set the entity belongs to
      # attrs   - Hash of attributes to set on the record.
      #
      # Examples
      #
      #   # Update the lead with id '073ca9c8-2a41-e911-a81d-000d3a1d5a0b'
      #   client.update('leads', "leadid": '073ca9c8-2a41-e911-a81d-000d3a1d5a0b', Name: 'Whizbang Corp')
      #
      # Returns true if the sobject was successfully updated.
      # Returns false if there was an error.
      def update(*args)
        update!(*args)
      rescue *exceptions
        false
      end

      # Public: Update a record.
      #
      # entity_set - The set the entity belongs to
      # attrs   - Hash of attributes to set on the record.
      #
      # Examples
      #
      #   # Update the leads with id '073ca9c8-2a41-e911-a81d-000d3a1d5a0b'
      #   client.update!('leads', 'leadid' => '073ca9c8-2a41-e911-a81d-000d3a1d5a0b', "firstname" => 'Whizbang Corp')
      #
      # Returns true if the sobject was successfully updated.
      # Raises an exception if an error is returned from Dynamics.
      def update!(entity_set, attrs)
        entity = service[entity_set].new_entity(attrs)
        url_chunk = to_url_chunk(entity)

        raise ArgumentError, 'ID field missing from provided attributes' if entity.is_new?

        api_patch url_chunk, attrs
        true
      end

      # Public: Delete a record.
      #
      # sobject - String name of the sobject.
      # id      - The Dynamics primary key ID of the record.
      #
      # Examples
      #
      #   # Delete the Account with Id  "073ca9c8-2a41-e911-a81d-000d3a1d5a0b"
      #   client.destroy('leads',  "073ca9c8-2a41-e911-a81d-000d3a1d5a0b")
      #
      # Returns true if the sobject was successfully deleted.
      # Returns false if an error is returned from Dynamics.
      def destroy(*args)
        destroy!(*args)
      rescue *exceptions
        false
      end

      # Public: Delete a record.
      #
      # entity_set - The set the entity belongs to
      # id      - The Dynamics primary key ID of the record.
      #
      # Examples
      #
      #   # Delete the Account with Id  "073ca9c8-2a41-e911-a81d-000d3a1d5a0b"
      #   client.destroy('leads',  "073ca9c8-2a41-e911-a81d-000d3a1d5a0b")
      #
      # Returns true of the sobject was successfully deleted.
      # Raises an exception if an error is returned from Dynamics.
      def destroy!(entity_set, id)
        query = service[entity_set].query
        url_chunk = query.find(id).to_s
        api_delete url_chunk
        true
      end

      # Public: Finds a single record and returns all fields.
      #
      # entity_set - The set the entity belongs to
      # id      - The id of the record. If field is specified, id should be the id
      #           of the external field.
      # field   - External ID field to use (default: nil).
      #
      # Returns the Enitity record.
      def find(entity_set, id, field = nil)
        query = service[entity_set].query
        url_chunk = if field
                      query.where("#{field} eq #{id}")
                    else
                      query.find(id).to_s
                    end
        body = api_get(url_chunk).body

        FrOData::Entity.from_json( e['value'].first, c.service['leads'].entity_options)
      end

      # Public: Finds a single record and returns select fields.
      #
      # entity_set - The set the entity belongs to
      # id      - The id of the record. If field is specified, id should be the id
      #           of the external field.
      # select  - A String array denoting the fields to select.  If nil or empty array
      #           is passed, all fields are selected.
      # field   - External ID field to use (default: nil).
      #
      def select(entity_set, id, select, field = nil)
        query = service[entity_set].query
        p query.to_s

        select.each{|field| query.select(field)}

        p query.to_s
        url_chunk = if field
                      query.where("#{field} eq #{id}")
                    else
                      query.find(id).to_s
                    end


        path = if field
               "sobjects/#{sobject}/#{field}/#{ERB::Util.url_encode(id)}"
               else
                 "sobjects/#{sobject}/#{ERB::Util.url_encode(id)}"
               end

        path = "#{path}?fields=#{select.join(',')}" if select&.any?

        api_get(path).body
      end

      private

      # Internal: Returns a path to an api endpoint
      #
      # Examples
      #
      #   api_path('sobjects')
      #   # => '/services/data/v24.0/sobjects'
      def api_path(path)
        "/api/data/v#{options[:api_version]}/#{path}"
      end

      def build_entity(entity_set, data)
        entity_options = client.service[set].entity_options
        single_entity?(body) ? parse_entity(data, entity_options) : parse_entities(data, entity_options)
      end

      def single_entity?(body)
        body['@odata.context'] =~ /\$entity$/
      end

      def parse_entity(body, entity_options)
        FrOData::Entity.from_json(entity_json, entity_options)
      end

      def parse_entities(body, entity_options)
        body['value'].map  do |entity_data|
          FrOData::Entity.from_json(entity_data, entity_options)
        end
      end

      def to_url_chunk(entity)
        primary_key = entity.get_property(entity.primary_key).url_value
        set = entity.entity_set.name
        entity.is_new? ? set : "#{set}(#{primary_key})"
      end

      # Internal: Errors that should be rescued from in non-bang methods
      def exceptions
        [Faraday::Error::ClientError]
      end
    end
  end
end
