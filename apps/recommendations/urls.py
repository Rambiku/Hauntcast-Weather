# apps/recommendations/urls.py
from django.urls import path

from .views import RecommendationDetailView

urlpatterns = [
    path("recommendations", RecommendationDetailView.as_view(), name="recommendation-detail"),
]
