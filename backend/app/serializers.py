from rest_framework import serializers
from django.contrib.auth.models import User
from .models import BookingSlot, Expense, ExpenseShare, Trip, TripMember, TripTask
from .splits import equal_split


class TripMemberSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = TripMember
        fields = ['user', 'username', 'role']
        read_only_fields = ['role']


class TripSerializer(serializers.ModelSerializer):
    owner = serializers.CharField(source='owner.username', read_only=True)
    members = TripMemberSerializer(source='trip_members', many=True, read_only=True)

    class Meta:
        model = Trip
        fields = ['id', 'title', 'destination', 'start_date', 'end_date', 'status', 'owner', 'members']
        read_only_fields = ['owner', 'members']

    def validate(self, attrs):
        start = attrs.get('start_date', getattr(self.instance, 'start_date', None))
        end = attrs.get('end_date', getattr(self.instance, 'end_date', None))
        if start and end and end < start:
            raise serializers.ValidationError('End date must not be before start date.')
        return attrs


class BookingSlotSerializer(serializers.ModelSerializer):
    booked_count = serializers.IntegerField(source='booked_by.count', read_only=True)

    class Meta:
        model = BookingSlot
        fields = ['id', 'trip', 'title', 'slot_type', 'capacity', 'price', 'booked_count']
        read_only_fields = ['trip', 'booked_count']


class ExpenseShareSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = ExpenseShare
        fields = ['user', 'username', 'amount']


class ExpenseSerializer(serializers.ModelSerializer):
    shares = ExpenseShareSerializer(many=True, required=False)
    paid_by_name = serializers.CharField(source='paid_by.username', read_only=True)

    class Meta:
        model = Expense
        fields = ['id', 'trip', 'paid_by', 'paid_by_name', 'description', 'amount', 'split_type', 'shares', 'created_at']
        read_only_fields = ['trip', 'paid_by', 'created_at']

    def validate(self, attrs):
        shares = attrs.get('shares', [])
        amount = attrs.get('amount', getattr(self.instance, 'amount', None))
        if amount is not None and amount <= 0:
            raise serializers.ValidationError('Amount must be greater than zero.')
        if shares and sum((share['amount'] for share in shares), 0) != amount:
            raise serializers.ValidationError('Expense shares must add up to the total amount.')
        if (
            self.instance
            and not shares
            and amount != self.instance.amount
            and self.instance.split_type == Expense.SplitType.CUSTOM
        ):
            raise serializers.ValidationError('Provide new shares when changing a custom-split amount.')
        return attrs

    def create(self, validated_data):
        shares = validated_data.pop('shares')
        expense = Expense.objects.create(**validated_data)
        ExpenseShare.objects.bulk_create([
            ExpenseShare(expense=expense, **share) for share in shares
        ])
        return expense

    def update(self, instance, validated_data):
        shares = validated_data.pop('shares', None)
        amount_changed = 'amount' in validated_data and validated_data['amount'] != instance.amount
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if shares is None and amount_changed and instance.split_type == Expense.SplitType.EQUAL:
            user_ids = list(instance.shares.values_list('user_id', flat=True))
            if user_ids:
                shares = equal_split(instance.amount, user_ids)
        if shares is not None:
            instance.shares.all().delete()
            ExpenseShare.objects.bulk_create([
                ExpenseShare(
                    expense=instance,
                    user_id=getattr(share['user'], 'pk', share['user']),
                    amount=share['amount'],
                )
                for share in shares
            ])
        return instance


class TripTaskSerializer(serializers.ModelSerializer):
    assigned_to_name = serializers.CharField(source='assigned_to.username', read_only=True)

    class Meta:
        model = TripTask
        fields = ['id', 'trip', 'title', 'description', 'category', 'assigned_to', 'assigned_to_name', 'due_date', 'is_done']
        read_only_fields = ['trip', 'assigned_to_name']
