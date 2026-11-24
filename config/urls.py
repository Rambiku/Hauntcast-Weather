"""URL configuration for Hauntcast Weather."""
from django.urls import path, include

urlpatterns = [
    path("api/v1/locations/", include("apps.locations.urls")),
    # Future apps add their routes here under api/v1/<app>/
]
