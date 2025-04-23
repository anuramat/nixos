c = get_config()  # pyright: ignore[reportUndefinedVariable]

#  Default: 'localhost'
c.ServerApp.ip = "0.0.0.0"

c.ServerApp.open_browser = False

## DEPRECATED in 2.0. Use PasswordIdentityProvider.hashed_password
#  Default: ''
c.ServerApp.password = ""

## DEPRECATED in 2.0. Use PasswordIdentityProvider.password_required
#  Default: False
c.ServerApp.password_required = False

c.ServerApp.port = 8888

## DEPRECATED. Use IdentityProvider.token
#  Default: '<DEPRECATED>'
c.ServerApp.token = ""

# allow access to hidden files
c.ContentsManager.allow_hidden = False

# to make remote molten work
c.ServerApp.disable_check_xsrf = True
