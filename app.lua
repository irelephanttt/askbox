local lapis = require("lapis")
local app = lapis.Application()
local date = require("date")

app:enable("etlua")
app.layout =  require("views.layout")


app:include(require("src.user"))
app:include(require("src.accounts"))
app:include(require("src.asks"))
app:include(require("src.inbox"))
app:include(require("src.posts"))
app:include(require("src.feed"))

-- set the expiry date for cookies. currently, 100 days
app.cookie_attributes = function(self)
  local expires = date(true):adddays(100):fmt("${http}")
  return "Expires=" .. expires .. "; Path=/; HttpOnly"
end


-- setup the session
app:before_filter(function(self)
  if self.session.current_user then
    self.is_logged_in = true
  elseif not self.session.current_user then
    self.is_logged_in = false
  end
end)


return app
