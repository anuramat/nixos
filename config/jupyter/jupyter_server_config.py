c = get_config()  # pyright: ignore[reportUndefinedVariable]

c.ServerApp.ip = "0.0.0.0"
c.ServerApp.port = 8888
c.ServerApp.open_browser = False

# disables auth; deprecated
c.ServerApp.password = ""
c.ServerApp.token = ""

# allow access to hidden files
c.ContentsManager.allow_hidden = False

# to make remote molten work
c.ServerApp.disable_check_xsrf = True
