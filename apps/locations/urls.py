from django.urls import path
from .views import SupabaseConnectionView

urlpatterns = [
    path("test-connection/", SupabaseConnectionView.as_view()),
]