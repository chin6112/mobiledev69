from django.contrib.auth.models import User
from django.core.management import call_command
from django.core.management.base import BaseCommand
from oidc_provider.models import Client, ResponseType, RSAKey

CLIENT_ID = 'tripmate-flutter'
REDIRECT_URIS = ['http://localhost:50000/callback']
POST_LOGOUT_REDIRECT_URIS = ['http://localhost:50000/']
DEMO_USERNAME = 'demo'
DEMO_PASSWORD = 'demo-pass-1234'


class Command(BaseCommand):
    help = 'Create the RSA signing key, the public PKCE OIDC client for the Flutter app, and a demo user.'

    def handle(self, *args, **options):
        if not RSAKey.objects.exists():
            call_command('creatersakey')

        client, created = Client.objects.get_or_create(
            client_id=CLIENT_ID,
            defaults={'name': 'TripMate Flutter', 'client_type': 'public', 'jwt_alg': 'RS256'},
        )
        client.client_type = 'public'
        client.client_secret = ''
        client.require_consent = False
        client.reuse_consent = True
        client.redirect_uris = REDIRECT_URIS
        client.post_logout_redirect_uris = POST_LOGOUT_REDIRECT_URIS
        client.scope = ['openid', 'profile', 'email']
        client.save()
        client.response_types.set(ResponseType.objects.filter(value='code'))

        user, user_created = User.objects.get_or_create(username=DEMO_USERNAME, defaults={'email': 'demo@example.com'})
        if user_created:
            user.set_password(DEMO_PASSWORD)
            user.save()

        self.stdout.write(self.style.SUCCESS(f'OIDC client "{CLIENT_ID}" ready ({"created" if created else "updated"}).'))
        self.stdout.write(f'Demo account: {DEMO_USERNAME} / {DEMO_PASSWORD}' if user_created else f'Demo account "{DEMO_USERNAME}" already exists.')
