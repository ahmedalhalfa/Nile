# spec/swagger_helper.rb
require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api Gem, you should decide where to store the generated Swagger files
  # Otherwise, set this value to nil
  config.openapi_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the metadata defined here will
  # be applied to the corresponding Swagger document. Be sure to specify a openapi_spec V3 here
  # Refer to https://github.com/rswag/rswag#swagger-doc-configuration for more details
  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Nile API V1",
        version: "v1"
      },
      paths: {},
      servers: [
        {
          url: "http://{defaultHost}",
          variables: {
            defaultHost: {
              default: "localhost:3000"
            }
          }
        }
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer
          }
        },
        schemas: {
          errors_object: {
            type: :object,
            properties: {
              errors: { type: :array, items: { type: :string } }
            }
          },
          book: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              author_name: { type: :string },
              author_age: { type: :integer, nullable: true }
            },
            required: [ "id", "title", "author_name" ]
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
