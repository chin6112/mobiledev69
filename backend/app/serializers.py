from rest_framework import serializers
from django.contrib.auth.models import User
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import Booking, BookingSlot, Expense, ExpenseShare, Trip, TripMember, TripTask

class BookingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Booking
        fields = ['id', 'destination_name', 'start_date', 'end_date', 'price']
        # custom serializer สำหรับล็อกอินเพื่อส่งกลับ Custom Token Claims


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
        if shares and sum((share['amount'] for share in shares), 0) != attrs['amount']:
            raise serializers.ValidationError('Expense shares must add up to the total amount.')
        return attrs

    def create(self, validated_data):
        shares = validated_data.pop('shares')
        expense = Expense.objects.create(**validated_data)
        ExpenseShare.objects.bulk_create([
            ExpenseShare(expense=expense, **share) for share in shares
        ])
        return expense


class TripTaskSerializer(serializers.ModelSerializer):
    assigned_to_name = serializers.CharField(source='assigned_to.username', read_only=True)

    class Meta:
        model = TripTask
        fields = ['id', 'trip', 'title', 'description', 'category', 'assigned_to', 'assigned_to_name', 'due_date', 'is_done']
        read_only_fields = ['trip', 'assigned_to_name']


class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # เพิ่ม Custom Claim ลงใน Token
        token['name'] = user.username
        return token