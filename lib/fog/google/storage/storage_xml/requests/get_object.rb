module Fog
  module Google
    class StorageXML
      class Real
        # Get an object from Google Storage
        #
        # ==== Parameters
        # * bucket_name<~String> - Name of bucket to read from
        # * object_name<~String> - Name of object to read
        # * options<~Hash>:
        #   * 'If-Match'<~String> - Returns object only if its etag matches this value, otherwise returns 412 (Precondition Failed).
        #   * 'If-Modified-Since'<~Time> - Returns object only if it has been modified since this time, otherwise returns 304 (Not Modified).
        #   * 'If-None-Match'<~String> - Returns object only if its etag differs from this value, otherwise returns 304 (Not Modified)
        #   * 'If-Unmodified-Since'<~Time> - Returns object only if it has not been modified since this time, otherwise returns 412 (Precodition Failed).
        #   * 'Range'<~String> - Range of object to download
        #   * 'versionId'<~String> - specify a particular version to retrieve
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~String> - Contents of object
        #   * headers<~Hash>:
        #     * 'Content-Length'<~String> - Size of object contents
        #     * 'Content-Type'<~String> - MIME type of object
        #     * 'ETag'<~String> - Etag of object
        #     * 'Last-Modified'<~String> - Last modified timestamp for object
        #
        def get_object(bucket_name, object_name, options = {}, &block)
          raise ArgumentError.new("bucket_name is required") unless bucket_name
          raise ArgumentError.new("object_name is required") unless object_name

          params = { :headers => {} }
          if version_id = options.delete("versionId")
            params[:query] = { "versionId" => version_id }
          end
          params[:headers].merge!(options)
          if options["If-Modified-Since"]
            params[:headers]["If-Modified-Since"] = Fog::Time.at(options["If-Modified-Since"].to_i).to_date_header
          end
          if options["If-Modified-Since"]
            params[:headers]["If-Unmodified-Since"] = Fog::Time.at(options["If-Unmodified-Since"].to_i).to_date_header
          end

          params[:response_block] = block if block_given?

          request(params.merge!(:expects        => [200, 206],
                                :host           => "#{bucket_name}.#{@host}",
                                :idempotent     => true,
                                :method         => "GET",
                                :path           => Fog::Google.escape(object_name)))
        end
      end

      class Mock
        def get_object(bucket_name, object_name, options = {})
          raise ArgumentError.new("bucket_name is required") unless bucket_name
          raise ArgumentError.new("object_name is required") unless object_name
          response = Excon::Response.new
          if (bucket = data[:buckets][bucket_name]) && (object = bucket[:objects][object_name])
            if options["If-Match"] && options["If-Match"] != object["ETag"]
              response.status = 412
            elsif options["If-Modified-Since"] && options["If-Modified-Since"] >= Time.parse(object["Last-Modified"])
              response.status = 304
            elsif options["If-None-Match"] && options["If-None-Match"] == object["ETag"]
              response.status = 304
            elsif options["If-Unmodified-Since"] && options["If-Unmodified-Since"] < Time.parse(object["Last-Modified"])
              response.status = 412
            else
              response.status = 200
              for key, value in object
                case key
                when "Cache-Control", "Content-Disposition", "Content-Encoding", "Content-Length", "Content-MD5", "Content-Type", "ETag", "Expires", "Last-Modified", /^x-goog-meta-/
                  response.headers[key] = value
                end
              end
              if block_given?
                data = StringIO.new(object[:body])
                remaining = data.length
                while remaining > 0
                  chunk = data.read([remaining, Excon::CHUNK_SIZE].min)
                  yield(chunk)
                  remaining -= Excon::CHUNK_SIZE
                end
              else
                response.body = object[:body]
              end
            end
          else
            response.status = 404
            raise(Excon::Errors.status_error({ :expects => 200 }, response))
          end
          response
        end
      end
    end
  end
end
