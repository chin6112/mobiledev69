from decimal import Decimal, ROUND_DOWN


def equal_split(amount, user_ids):
    """Split `amount` evenly; the rounding remainder goes to the first user."""
    amount = Decimal(str(amount))
    unit = (amount / len(user_ids)).quantize(Decimal('0.01'), rounding=ROUND_DOWN)
    remainder = amount - unit * len(user_ids)
    return [
        {'user': user_id, 'amount': unit + (remainder if index == 0 else Decimal('0.00'))}
        for index, user_id in enumerate(user_ids)
    ]
