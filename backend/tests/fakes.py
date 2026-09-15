"""A minimal fake standing in for supabase-py's Client, just deep enough to
exercise app/api/v1/auth.py without hitting the network. Not a general
Supabase mock — extend narrowly if another route needs one."""


class _FakeSession:
    def __init__(self, access="fake-access-token", refresh="fake-refresh-token"):
        self.access_token = access
        self.refresh_token = refresh


class _FakeAuthUser:
    def __init__(self, id="usr-1"):
        self.id = id


class _FakeAuthResponse:
    def __init__(self, session, user):
        self.session = session
        self.user = user


class FakeAuth:
    def __init__(self, *, fail: bool = False, no_session: bool = False):
        self.fail = fail
        self.no_session = no_session

    def _result(self):
        if self.fail:
            raise Exception("simulated Supabase Auth failure")
        if self.no_session:
            return _FakeAuthResponse(None, None)
        return _FakeAuthResponse(_FakeSession(), _FakeAuthUser())

    def sign_in_with_password(self, _creds):
        return self._result()

    def sign_up(self, _payload):
        return self._result()

    def sign_in_with_id_token(self, _payload):
        return self._result()

    def refresh_session(self, _token):
        return self._result()


class _FakeResult:
    def __init__(self, data):
        self.data = data


class _FakeTableQuery:
    """Chainable no-op query builder — every filter/order call just returns
    `self`, and `execute()` returns whatever data the table was seeded with."""

    def __init__(self, data):
        self._data = data

    def select(self, *_a, **_k):
        return self

    def eq(self, *_a, **_k):
        return self

    def maybe_single(self):
        return self

    def order(self, *_a, **_k):
        return self

    def execute(self):
        return _FakeResult(self._data)


class FakeSupabaseClient:
    def __init__(self, auth: FakeAuth, profile: dict):
        self.auth = auth
        self._profile = profile

    def table(self, name: str):
        if name == "profiles":
            return _FakeTableQuery(self._profile)
        return _FakeTableQuery([])
