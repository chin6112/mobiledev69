def userinfo(claims, user):
    claims['name'] = user.get_full_name() or user.username
    claims['preferred_username'] = user.username
    claims['email'] = user.email
    return claims
