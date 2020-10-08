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
    path('ajax/medDRA-tree', views.get_medDRA_tree, name='get_medDRA_tree'),
    path('ajax/conds-nodes-ids', views.get_conditions_nodes_ids, name='conds_nodes_ids'),
    path('OpenFDAWorkspace/', views.OpenFDAWorkspace, name='OpenFDAWorkspace'),
    path('OpenFDAWorkspace/<int:scenario_id>', views.OpenFDAWorkspace, name='OpenFDAWorkspace'),
    path('LiteratureWorkspace/<int:scenario_id>', views.pubMed_view, name='LiteratureWorkspace'),
    path('LiteratureWorkspace/<int:scenario_id>/<int:page_id>', views.pubMed_view, name='LiteratureWorkspace'),
    path("ajax/save_pubmed_input/", views.save_pubmed_input, name='save_pubmed_input'),
    path("ajax/mendeley_login", views.is_logged_in, name='mendeley_login'),
    path("edit-scenario/ajax/mendeley_login", views.is_logged_in, name='mendeley_login'),
    path("paper_notes_view", views.paper_notes_view, name='paper_notes'),


    # Permission denied
    path('denied', views.unauthorized, name='unauthorized'),
]
