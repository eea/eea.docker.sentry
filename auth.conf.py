
import ldap
from django_auth_ldap.config import LDAPSearch, LDAPSearchUnion

AUTH_LDAP_SERVER_URI = env('LDAP_SERVER', 'ldap://localhost')

AUTH_LDAP_BIND_DN = env('LDAP_BIND_DN', '')
AUTH_LDAP_BIND_PASSWORD = env('LDAP_BIND_PASSWORD', '')
SENTRY_MANAGED_USER_FIELDS = ('email', 'first_name', 'last_name', 'password', )

AUTH_LDAP_USER_SEARCH = LDAPSearchUnion(
    LDAPSearch(env('LDAP_USER_DN'), ldap.SCOPE_SUBTREE, "(uid=%(user)s)"),
    LDAPSearch(env('LDAP_USER_DN'), ldap.SCOPE_SUBTREE, "(mail=%(user)s)"),
)

AUTH_LDAP_USER_ATTR_MAP = {
    'name': 'cn',
    'email': 'mail'
}

AUTH_LDAP_DEFAULT_SENTRY_ORGANIZATION = env(
    'LDAP_DEFAULT_SENTRY_ORGANIZATION',
    'eea')

AUTH_LDAP_SENTRY_ORGANIZATION_ROLE_TYPE = 'member'
AUTH_LDAP_SENTRY_SUBSCRIBE_BY_DEFAULT = True
AUTH_LDAP_SENTRY_ORGANIZATION_GLOBAL_ACCESS = True
AUTH_LDAP_FIND_GROUP_PERMS = False
AUTH_LDAP_SENTRY_USERNAME_FIELD = 'uid'

AUTHENTICATION_BACKENDS = AUTHENTICATION_BACKENDS + (
    'sentry_ldap_auth.backend.SentryLdapBackend',
)

# disable register on login page
SENTRY_FEATURES['auth:register'] = False

# setup logging for django_auth_ldap
import logging
logger = logging.getLogger('django_auth_ldap')
logger.addHandler(logging.StreamHandler())
ldap_loglevel = getattr(logging, env('LDAP_LOGLEVEL', 'DEBUG'))
logger.setLevel(ldap_loglevel)
LOGGING['overridable'] = ['sentry', 'django_auth_ldap']
LOGGING['loggers']['django_auth_ldap'] = {
    'handlers': ['console'],
    'level': 'DEBUG'
}
