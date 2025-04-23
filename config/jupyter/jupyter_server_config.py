c = get_config()  # pyright: ignore[reportUndefinedVariable]

## The IP address the Jupyter server will listen on.
#  Default: 'localhost'
c.ServerApp.ip = "0.0.0.0"

## Whether to open in a browser after starting.
#  Default: False
c.ServerApp.open_browser = False

## DEPRECATED in 2.0. Use PasswordIdentityProvider.hashed_password
#  Default: ''
c.ServerApp.password = ""

## DEPRECATED in 2.0. Use PasswordIdentityProvider.password_required
#  Default: False
c.ServerApp.password_required = False

## The port the server will listen on (env: JUPYTER_PORT).
#  Default: 0
c.ServerApp.port = 8888

## DEPRECATED. Use IdentityProvider.token
#  Default: '<DEPRECATED>'
c.ServerApp.token = ""

## Allow access to hidden files
#  Default: False
c.ContentsManager.allow_hidden = False
