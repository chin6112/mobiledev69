from oidc_provider.models import Token
from rest_framework.authentication import BaseAuthentication, get_authorization_header
from rest_framework.exceptions import AuthenticationFailed


class OIDCAccessTokenAuthentication(BaseAuthentication):
    """Authenticates `Authorization: Bearer <token>` using access tokens issued by django-oidc-provider."""

    keyword = b'bearer'

    def authenticate(self, request):
        parts = get_authorization_header(request).split()
        if not parts or parts[0].lower() != self.keyword:
            return None
        if len(parts) != 2:
            raise AuthenticationFailed('Invalid Authorization header.')

        try:
            access_token = parts[1].decode()
        except UnicodeError:
            raise AuthenticationFailed('Invalid Authorization header.')

        token = Token.objects.select_related('user').filter(access_token=access_token).first()
        if token is None or token.has_expired():
            raise AuthenticationFailed('Invalid or expired access token.')
        if not token.user.is_active:
            raise AuthenticationFailed('User is inactive.')
        return token.user, token

    def authenticate_header(self, request):
        return 'Bearer'
