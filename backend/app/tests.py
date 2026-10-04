from datetime import timedelta
from decimal import Decimal

from django.contrib.auth.models import User
from django.utils import timezone
from oidc_provider.models import Client, Token
from rest_framework import status
from rest_framework.test import APITestCase


class OIDCAuthenticationTests(APITestCase):
	def setUp(self):
		self.user = User.objects.create_user(username='oidc-user', password='strong-pass-123')
		self.oidc_client = Client.objects.create(name='test', client_id='test-client', client_type='public')

	def make_token(self, expires_in):
		token = Token(
			user=self.user,
			client=self.oidc_client,
			access_token='access-token-value',
			expires_at=timezone.now() + expires_in,
		)
		token.scope = ['openid']
		token.save()
		return token

	def test_valid_oidc_access_token_authenticates_request(self):
		self.make_token(timedelta(hours=1))
		self.client.credentials(HTTP_AUTHORIZATION='Bearer access-token-value')
		self.assertEqual(self.client.get('/api/trips/').status_code, status.HTTP_200_OK)

	def test_expired_token_is_rejected(self):
		self.make_token(timedelta(hours=-1))
		self.client.credentials(HTTP_AUTHORIZATION='Bearer access-token-value')
		self.assertEqual(self.client.get('/api/trips/').status_code, status.HTTP_401_UNAUTHORIZED)

	def test_unknown_token_and_missing_token_are_rejected(self):
		self.assertEqual(self.client.get('/api/trips/').status_code, status.HTTP_401_UNAUTHORIZED)
		self.client.credentials(HTTP_AUTHORIZATION='Bearer nope')
		self.assertEqual(self.client.get('/api/trips/').status_code, status.HTTP_401_UNAUTHORIZED)

	def test_password_register_endpoint_is_removed(self):
		response = self.client.post('/api/auth/register/', {'username': 'x', 'password': 'y'}, format='json')
		self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)


class TripMateApiTests(APITestCase):
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

	def test_settlement_includes_usernames_and_decimal_amount(self):
		owner = User.objects.create_user(username='payer', password='strong-pass-123')
		member = User.objects.create_user(username='receiver', password='strong-pass-123')
		self.client.force_authenticate(user=owner)
		trip_response = self.client.post(
			'/api/trips/',
			{
				'title': 'ยอดทริป',
				'destination': 'อุบลราชธานี',
				'start_date': '2026-12-10',
				'end_date': '2026-12-11',
			},
			format='json',
		)
		from app.models import Expense, ExpenseShare, Trip, TripMember

		trip = Trip.objects.get(id=trip_response.data['id'])
		TripMember.objects.create(trip=trip, user=member)
		expense = Expense.objects.create(trip=trip, paid_by=owner, description='อาหาร', amount='100.00')
		ExpenseShare.objects.create(expense=expense, user=owner, amount='50.00')
		ExpenseShare.objects.create(expense=expense, user=member, amount='50.00')
		response = self.client.get(f'/api/trips/{trip.id}/settlement/')
		self.assertEqual(response.status_code, status.HTTP_200_OK)
		self.assertEqual(response.data['transfers'][0]['from_username'], 'receiver')
		self.assertEqual(response.data['transfers'][0]['to_username'], 'payer')
		self.assertEqual(response.data['transfers'][0]['amount'], '50.00')


class TripCrudTests(APITestCase):
	def setUp(self):
		from app.models import Trip, TripMember

		self.owner = User.objects.create_user(username='crud-owner', password='strong-pass-123')
		self.member = User.objects.create_user(username='crud-member', password='strong-pass-123')
		self.outsider = User.objects.create_user(username='crud-outsider', password='strong-pass-123')
		self.client.force_authenticate(user=self.owner)
		response = self.client.post(
			'/api/trips/',
			{'title': 'Original', 'destination': 'Krabi', 'start_date': '2026-12-01', 'end_date': '2026-12-05'},
			format='json',
		)
		self.trip_id = response.data['id']
		TripMember.objects.create(trip=Trip.objects.get(id=self.trip_id), user=self.member)

	def test_owner_can_update_trip(self):
		response = self.client.patch(f'/api/trips/{self.trip_id}/', {'title': 'Renamed'}, format='json')
		self.assertEqual(response.status_code, status.HTTP_200_OK)
		self.assertEqual(response.data['title'], 'Renamed')

	def test_trip_end_before_start_is_rejected(self):
		response = self.client.patch(f'/api/trips/{self.trip_id}/', {'end_date': '2026-11-01'}, format='json')
		self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

	def test_member_cannot_edit_or_delete_trip(self):
		self.client.force_authenticate(user=self.member)
		self.assertEqual(self.client.patch(f'/api/trips/{self.trip_id}/', {'title': 'x'}, format='json').status_code, status.HTTP_403_FORBIDDEN)
		self.assertEqual(self.client.delete(f'/api/trips/{self.trip_id}/').status_code, status.HTTP_403_FORBIDDEN)

	def test_owner_can_delete_trip(self):
		self.assertEqual(self.client.delete(f'/api/trips/{self.trip_id}/').status_code, status.HTTP_204_NO_CONTENT)
		self.assertEqual(self.client.get(f'/api/trips/{self.trip_id}/').status_code, status.HTTP_404_NOT_FOUND)

	def test_non_member_cannot_see_trip(self):
		self.client.force_authenticate(user=self.outsider)
		self.assertEqual(self.client.get(f'/api/trips/{self.trip_id}/').status_code, status.HTTP_404_NOT_FOUND)

	def test_expense_update_resplits_and_delete_is_restricted(self):
		self.client.force_authenticate(user=self.member)
		created = self.client.post(
			f'/api/trips/{self.trip_id}/expenses/', {'description': 'Food', 'amount': '100.00'}, format='json'
		)
		self.assertEqual(created.status_code, status.HTTP_201_CREATED)
		expense_url = f"/api/expenses/{created.data['id']}/"
		updated = self.client.patch(expense_url, {'amount': '200.00', 'description': 'Dinner'}, format='json')
		self.assertEqual(updated.status_code, status.HTTP_200_OK)
		self.assertEqual(updated.data['description'], 'Dinner')
		self.assertEqual(sum(Decimal(share['amount']) for share in updated.data['shares']), Decimal('200.00'))
		self.client.force_authenticate(user=self.outsider)
		self.assertEqual(self.client.delete(expense_url).status_code, status.HTTP_404_NOT_FOUND)
		self.client.force_authenticate(user=self.member)
		self.assertEqual(self.client.delete(expense_url).status_code, status.HTTP_204_NO_CONTENT)

	def test_non_positive_expense_is_rejected(self):
		response = self.client.post(
			f'/api/trips/{self.trip_id}/expenses/', {'description': 'Free', 'amount': '0'}, format='json'
		)
		self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

	def test_task_can_be_deleted(self):
		task = self.client.post(f'/api/trips/{self.trip_id}/tasks/', {'title': 'Pack'}, format='json')
		response = self.client.delete(f"/api/tasks/{task.data['id']}/")
		self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
