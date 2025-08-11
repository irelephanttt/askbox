local config = require("lapis.config")

config("development", {
  server = "nginx",
  code_cache = "off",
  num_workers = "1",
  postgres = {
    user = "askbox",
    password = "",
    database = "askbox",
  },
  session_name = "ASKBOXSESSION",
  secret = "",
  

})
