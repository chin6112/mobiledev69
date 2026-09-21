from django.db import models
from django.contrib.auth.models import User

# Create your models here.
class Booking(models.Model):
    # id = models.AutoField(primary_key=True)
    destination_name = models.CharField(max_length=100, default="UBU")
    start_date = models.DateField(default=None, blank=True, null=True)
    end_date = models.DateField(default=None, blank=True, null=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return f"{self.destination_name} ({self.start_date} - {self.end_date})"


class Trip(models.Model):
    class Status(models.TextChoices):
        UPCOMING = 'upcoming', 'Upcoming'
        ONGOING = 'ongoing', 'Ongoing'
        DONE = 'done', 'Done'

    title = models.CharField(max_length=120)
    destination = models.CharField(max_length=120)
    start_date = models.DateField()
    end_date = models.DateField()
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.UPCOMING)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='owned_trips')
    created_at = models.DateTimeField(auto_now_add=True)
    members = models.ManyToManyField(User, through='TripMember', related_name='trips')

    class Meta:
        ordering = ['-start_date', '-created_at']

    def __str__(self):
        return self.title


class TripMember(models.Model):
    class Role(models.TextChoices):
        OWNER = 'owner', 'Owner'
        MEMBER = 'member', 'Member'

    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name='trip_members')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='trip_memberships')
    role = models.CharField(max_length=10, choices=Role.choices, default=Role.MEMBER)
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['trip', 'user'], name='unique_trip_member'),
        ]


class BookingSlot(models.Model):
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name='booking_slots')
    title = models.CharField(max_length=120)
    slot_type = models.CharField(max_length=30, default='activity')
    capacity = models.PositiveIntegerField(default=1)
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    booked_by = models.ManyToManyField(User, blank=True, related_name='booked_slots')

    def __str__(self):
        return f'{self.trip.title}: {self.title}'


class Expense(models.Model):
    class SplitType(models.TextChoices):
        EQUAL = 'equal', 'Equal'
        CUSTOM = 'custom', 'Custom'

    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name='expenses')
    paid_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name='paid_expenses')
    description = models.CharField(max_length=160)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    split_type = models.CharField(max_length=10, choices=SplitType.choices, default=SplitType.EQUAL)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.description}: {self.amount}'


class ExpenseShare(models.Model):
    expense = models.ForeignKey(Expense, on_delete=models.CASCADE, related_name='shares')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='expense_shares')
    amount = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['expense', 'user'], name='unique_expense_share'),
        ]


class TripTask(models.Model):
    class Category(models.TextChoices):
        URGENT = 'urgent', 'Urgent'
        WORK = 'work', 'Work'
        TEAM = 'team', 'Team'

    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name='tasks')
    title = models.CharField(max_length=160)
    description = models.TextField(blank=True)
    category = models.CharField(max_length=10, choices=Category.choices, default=Category.TEAM)
    assigned_to = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='trip_tasks',
    )
    due_date = models.DateField(null=True, blank=True)
    is_done = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['is_done', 'due_date', 'created_at']

    def __str__(self):
        return self.title