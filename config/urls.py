"""URL configuration for Hauntcast Weather."""
from django.urls import include, path

urlpatterns = [
    path("api/v1/locations/", include("apps.locations.urls")),
    path("api/v1/", include("apps.weather.urls")),
    path("api/v1/", include("apps.recommendations.urls")),
]
