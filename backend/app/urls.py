from .views import (
    BookingListView,
    SlotBookingView,
    TripDetailView,
    TripExpensesView,
    TripListCreateView,
    TripSettlementView,
    TripSlotsView,
    TripTaskDetailView,
    TripTasksView,
)
from django.urls import path

urlpatterns = [
    path('bookings/', BookingListView.as_view(), name='booking-list'),
    path('trips/', TripListCreateView.as_view(), name='trip-list-create'),
    path('trips/<int:trip_id>/', TripDetailView.as_view(), name='trip-detail'),
    path('trips/<int:trip_id>/slots/', TripSlotsView.as_view(), name='trip-slots'),
    path('slots/<int:slot_id>/book/', SlotBookingView.as_view(), name='slot-book'),
    path('trips/<int:trip_id>/expenses/', TripExpensesView.as_view(), name='trip-expenses'),
    path('trips/<int:trip_id>/settlement/', TripSettlementView.as_view(), name='trip-settlement'),
    path('trips/<int:trip_id>/tasks/', TripTasksView.as_view(), name='trip-tasks'),
    path('tasks/<int:task_id>/', TripTaskDetailView.as_view(), name='task-detail'),
]