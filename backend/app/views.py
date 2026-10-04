from collections import defaultdict
from decimal import Decimal

from django.db import transaction
from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from .models import BookingSlot, Expense, Trip, TripMember, TripTask
from .serializers import BookingSlotSerializer, ExpenseSerializer, TripSerializer, TripTaskSerializer
from .splits import equal_split

class TripListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        trips = Trip.objects.filter(members=request.user).prefetch_related('trip_members')
        return Response(TripSerializer(trips, many=True).data)

    @transaction.atomic
    def post(self, request):
        serializer = TripSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        trip = serializer.save(owner=request.user)
        TripMember.objects.create(trip=trip, user=request.user, role=TripMember.Role.OWNER)
        return Response(TripSerializer(trip).data, status=status.HTTP_201_CREATED)


class TripDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get_trip(self, request, trip_id):
        return get_object_or_404(Trip, id=trip_id, members=request.user)

    def get(self, request, trip_id):
        return Response(TripSerializer(self.get_trip(request, trip_id)).data)

    def patch(self, request, trip_id):
        trip = self.get_trip(request, trip_id)
        if trip.owner_id != request.user.id:
            return Response({'detail': 'Only the trip owner can edit this trip.'}, status=status.HTTP_403_FORBIDDEN)
        serializer = TripSerializer(trip, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        return Response(TripSerializer(serializer.save()).data)

    def delete(self, request, trip_id):
        trip = self.get_trip(request, trip_id)
        if trip.owner_id != request.user.id:
            return Response({'detail': 'Only the trip owner can delete this trip.'}, status=status.HTTP_403_FORBIDDEN)
        trip.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class TripSlotsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, trip_id):
        trip = get_object_or_404(Trip, id=trip_id, members=request.user)
        slots = trip.booking_slots.prefetch_related('booked_by')
        return Response(BookingSlotSerializer(slots, many=True).data)

    def post(self, request, trip_id):
        trip = get_object_or_404(Trip, id=trip_id, members=request.user)
        serializer = BookingSlotSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response(
            BookingSlotSerializer(serializer.save(trip=trip)).data,
            status=status.HTTP_201_CREATED,
        )


class SlotBookingView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, slot_id):
        slot = get_object_or_404(
            BookingSlot.objects.select_for_update(),
            id=slot_id,
            trip__members=request.user,
        )
        if slot.booked_by.count() >= slot.capacity:
            return Response({'detail': 'This slot is full.'}, status=status.HTTP_409_CONFLICT)
        slot.booked_by.add(request.user)
        return Response(BookingSlotSerializer(slot).data)


class TripExpensesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, trip_id):
        trip = get_object_or_404(Trip, id=trip_id, members=request.user)
        expenses = trip.expenses.select_related('paid_by').prefetch_related('shares__user')
        return Response(ExpenseSerializer(expenses, many=True).data)

    def post(self, request, trip_id):
        trip = get_object_or_404(Trip, id=trip_id, members=request.user)
        payload = request.data.copy()
        if not payload.get('shares'):
            members = list(trip.members.all())
            if not members:
                return Response({'detail': 'Trip has no members.'}, status=status.HTTP_400_BAD_REQUEST)
            amount = Decimal(str(payload.get('amount', '0')))
            payload['shares'] = equal_split(amount, [member.id for member in members])
        serializer = ExpenseSerializer(data=payload)
        serializer.is_valid(raise_exception=True)
        expense = serializer.save(trip=trip, paid_by=request.user)
        return Response(ExpenseSerializer(expense).data, status=status.HTTP_201_CREATED)


class ExpenseDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get_expense(self, request, expense_id):
        return get_object_or_404(
            Expense.objects.select_related('paid_by', 'trip').prefetch_related('shares__user'),
            id=expense_id,
            trip__members=request.user,
        )

    def _can_modify(self, request, expense):
        return request.user.id in (expense.paid_by_id, expense.trip.owner_id)

    def get(self, request, expense_id):
        return Response(ExpenseSerializer(self.get_expense(request, expense_id)).data)

    @transaction.atomic
    def patch(self, request, expense_id):
        expense = self.get_expense(request, expense_id)
        if not self._can_modify(request, expense):
            return Response({'detail': 'Only the payer or trip owner can edit this expense.'}, status=status.HTTP_403_FORBIDDEN)
        serializer = ExpenseSerializer(expense, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(ExpenseSerializer(self.get_expense(request, expense_id)).data)

    def delete(self, request, expense_id):
        expense = self.get_expense(request, expense_id)
        if not self._can_modify(request, expense):
            return Response({'detail': 'Only the payer or trip owner can delete this expense.'}, status=status.HTTP_403_FORBIDDEN)
        expense.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class TripSettlementView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, trip_id):
        trip = get_object_or_404(Trip, id=trip_id, members=request.user)
        balances = defaultdict(Decimal)
        for expense in trip.expenses.all():
            balances[expense.paid_by_id] += expense.amount
            for share in expense.shares.all():
                balances[share.user_id] -= share.amount

        creditors = [[user_id, amount] for user_id, amount in balances.items() if amount > 0]
        debtors = [[user_id, -amount] for user_id, amount in balances.items() if amount < 0]
        usernames = dict(
            trip.members.filter(id__in=balances.keys()).values_list('id', 'username')
        )
        transfers = []
        creditor_index = debtor_index = 0
        while creditor_index < len(creditors) and debtor_index < len(debtors):
            creditor_id, credit = creditors[creditor_index]
            debtor_id, debt = debtors[debtor_index]
            amount = min(credit, debt)
            transfers.append({
                'from_user': debtor_id,
                'from_username': usernames[debtor_id],
                'to_user': creditor_id,
                'to_username': usernames[creditor_id],
                'amount': str(amount.quantize(Decimal('0.01'))),
            })
            creditors[creditor_index][1] -= amount
            debtors[debtor_index][1] -= amount
            if creditors[creditor_index][1] == 0:
                creditor_index += 1
            if debtors[debtor_index][1] == 0:
                debtor_index += 1
        return Response({'transfers': transfers})


class TripTasksView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, trip_id):
        trip = get_object_or_404(Trip, id=trip_id, members=request.user)
        tasks = trip.tasks.select_related('assigned_to')
        return Response(TripTaskSerializer(tasks, many=True).data)

    def post(self, request, trip_id):
        trip = get_object_or_404(Trip, id=trip_id, members=request.user)
        serializer = TripTaskSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        task = serializer.save(trip=trip)
        return Response(TripTaskSerializer(task).data, status=status.HTTP_201_CREATED)


class TripTaskDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, task_id):
        task = get_object_or_404(TripTask, id=task_id, trip__members=request.user)
        serializer = TripTaskSerializer(task, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        return Response(TripTaskSerializer(serializer.save()).data)

    def delete(self, request, task_id):
        task = get_object_or_404(TripTask, id=task_id, trip__members=request.user)
        task.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
