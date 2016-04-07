local spec_helper = require "spec.spec_helpers"
local http_client = require "kong.tools.http_client"
local cjson = require "cjson"

local STUB_GET_URL = spec_helper.STUB_GET_URL
local STUB_POST_URL = spec_helper.STUB_POST_URL

describe("Header Transfer.", function()

  setup(function()
    spec_helper.prepare_db()
    spec_helper.insert_fixtures {
      api = {
        {name = "tests-request-transformer-1", request_host = "test1.com", upstream_url = "http://mockbin.com"}
      },
      plugin = {
        {
          name = "header-transfer",
          config = {
            head_to_body = {"h1:v1", "h2:v2"}
          },
          __api = 1
        }
      }
    }
    spec_helper.start_kong()
  end)

  teardown(function()
    spec_helper.stop_kong()
  end)

  describe("Test header to body", function()
    it("should remove specified header", function()
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "test1.com", ["h1"] = "this header will be removed", ["x-another-header"] = "true"})
      local body = cjson.decode(response)
      assert.equal(200, status)
      assert.falsy(body.headers["h1"])
      assert.equal("this header will be removed", body.queryString["v1"])
      assert.equal("true", body.headers["x-another-header"])
    end)

    it("should add specified arguments to body on POST", function()
      local response, status = http_client.post(STUB_POST_URL, {hello = "world"}, {host = "test1.com", ["h1"] = "2333333333"})
      local body = cjson.decode(response)
      assert.equal(200, status)
      assert.falsy(body.headers["h1"])
      assert.equal("world", body.postData.params["hello"])
      assert.equal("2333333333", body.postData.params["v1"])
    end)
  end)
end)
