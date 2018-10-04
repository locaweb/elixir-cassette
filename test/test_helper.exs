ExUnit.configure(capture_log: true)
Application.ensure_all_started(:cassette)
ExUnit.start()

# sets up the default instance to use a fake cas we start
FakeCas.Support.initialize()
