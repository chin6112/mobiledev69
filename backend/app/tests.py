from django.contrib.auth.models import User
from rest_framework import status
from rest_framework.test import APITestCase


class TripMateApiTests(APITestCase):
	def test_user_can_register_and_get_jwt(self):
		response = self.client.post(
			'/api/auth/register/',
			{'username': 'pete', 'password': 'strong-pass-123'},
			format='json',
		)
		self.assertEqual(response.status_code, status.HTTP_201_CREATED)
		token_response = self.client.post(
			'/api/token/',
			{'username': 'pete', 'password': 'strong-pass-123'},
			format='json',
		)
		self.assertEqual(token_response.status_code, status.HTTP_200_OK)
		self.assertIn('access', token_response.data)

	def test_authenticated_user_can_create_trip(self):
		user = User.objects.create_user(username='pete', password='strong-pass-123')
		self.client.force_authenticate(user=user)
		response = self.client.post(
			'/api/trips/',
			{
				'title': 'เชียงใหม่หน้าฝน',
				'destination': 'เชียงใหม่',
				'start_date': '2026-10-12',
				'end_date': '2026-10-15',
			},
			format='json',
		)
		self.assertEqual(response.status_code, status.HTTP_201_CREATED)
		self.assertEqual(response.data['title'], 'เชียงใหม่หน้าฝน')

	def test_expense_is_split_between_trip_members_when_shares_are_omitted(self):
		owner = User.objects.create_user(username='owner', password='strong-pass-123')
		member = User.objects.create_user(username='member', password='strong-pass-123')
		self.client.force_authenticate(user=owner)
		trip_response = self.client.post(
			'/api/trips/',
			{
				'title': 'หารค่าใช้จ่าย',
				'destination': 'เขาใหญ่',
				'start_date': '2026-11-01',
				'end_date': '2026-11-02',
			},
			format='json',
		)
		trip_id = trip_response.data['id']
		from app.models import Trip, TripMember

		trip = Trip.objects.get(id=trip_id)
		TripMember.objects.create(trip=trip, user=member)
		expense_response = self.client.post(
			f'/api/trips/{trip_id}/expenses/',
			{'description': 'ค่าอาหาร', 'amount': '100.00'},
			format='json',
		)
		self.assertEqual(expense_response.status_code, status.HTTP_201_CREATED)
		self.assertEqual(len(expense_response.data['shares']), 2)

	def test_member_can_complete_trip_task(self):
		user = User.objects.create_user(username='task-user', password='strong-pass-123')
		self.client.force_authenticate(user=user)
		trip_response = self.client.post(
			'/api/trips/',
			{
				'title': 'งานทริป',
				'destination': 'พัทยา',
				'start_date': '2026-12-01',
				'end_date': '2026-12-02',
			},
			format='json',
		)
		task_response = self.client.post(
			f"/api/trips/{trip_response.data['id']}/tasks/",
			{'title': 'จองตั๋วรถไฟ'},
			format='json',
		)
		self.assertEqual(task_response.status_code, status.HTTP_201_CREATED)
		update_response = self.client.patch(
			f"/api/tasks/{task_response.data['id']}/",
			{'is_done': True},
			format='json',
		)
		self.assertEqual(update_response.status_code, status.HTTP_200_OK)
		self.assertTrue(update_response.data['is_done'])
