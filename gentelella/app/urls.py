from django.urls import path, re_path
from app import views
from django.views.generic.base import RedirectView


urlpatterns = [
    # Matches any html file - to be used for gentella
    # Avoid using your .html in your resources.
    # Or create a separate django app.
    # re_path(r'^.*\.html', views.gentella_html, name='gentella'),

    # The home page
    path('', RedirectView.as_view(url="dashboard", permanent=False), name='index'),
    path('dashboard', views.index, name='index'),
    # path('dashboard', RedirectView.as_view(url='', permanent=False), name='index'),
    path('add-scenario', views.add_edit_scenario, name='add_scenario'),
    path('edit-scenario/<int:scenario_id>', views.add_edit_scenario, name='edit_scenario'),
    path('ajax/synonyms', views.get_synonyms, name='drugs_synonyms'),
    path('ajax/filter-whole-set', views.filter_whole_set, name='filter_whole_set'),
    path('ajax/all-drugs', views.get_all_drugs, name='get_all_drugs'),
    path('OpenFDAWorkspace_detailedView/', views.OpenFDAWorkspace_detailedView, name='OpenFDAWorkspace_detailedView'),
    path('OpenFDAWorkspace_detailedView/<int:scenario_id>',
         views.OpenFDAWorkspace_detailedView, name='OpenFDAWorkspace_detailedView'),
    # Permission denied
    path('denied', views.unauthorized, name='unauthorized'),
]
