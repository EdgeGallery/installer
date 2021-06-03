local typedefs = require "kong.db.schema.typedefs"


local schema = {
  name = "appid-header",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        -- The 'config' record is the custom part of the plugin schema
        type = "record",
        fields = {
        },
      },
    },
  },
}

return schema
