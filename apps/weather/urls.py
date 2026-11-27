# apps/weather/urls.py
from django.urls import path

from .views import HazardListView

urlpatterns = [
    path("hazards", HazardListView.as_view(), name="hazard-list"),
]
