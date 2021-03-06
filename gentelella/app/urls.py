from django.conf.urls.static import static
from django.conf import settings
from django.urls import path, re_path, include
from app import views
from django.views.generic.base import RedirectView


urlpatterns = [
    # Matches any html file - to be used for gentella
    # Avoid using your .html in your resources.
    # Or create a separate django app.
    # re_path(r'^.*\.html', views.gentella_html, name='gentella'),

    # The home page
    path('', views.index, name='index'),
    # path('', RedirectView.as_view(url="dashboard", permanent=False), name='index'),
    # path('dashboard', views.index, name='index'),
    # path('dashboard', RedirectView.as_view(url='', permanent=False), name='index'),
    path('add-scenario', views.add_edit_scenario, name='add_scenario'),
    path('edit-scenario/<int:scenario_id>', views.add_edit_scenario, name='edit_scenario'),
    path('ohdsi-workspace/drug-exposure', views.drug_exposure, name='drug_exposure'),
    path('ohdsi-workspace/condition-occurrence', views.condition_occurrence, name='condition_occurrence'),
    path('ohdsi-workspace/ir', views.incidence_rates, name='add_ir'),
    path('ohdsi-workspace/ir/<int:sc_id>/<int:ir_id>', views.incidence_rates, name='edit_ir'),
    path('ohdsi-workspace/ir/<int:sc_id>/<int:ir_id>/<int:read_only>', views.incidence_rates, name='edit_ir'),
    path('ohdsi-workspace/ir/<slug:view_type>/<int:sc_id>/<int:ir_id>', views.incidence_rates, name='edit_ir'),
    path('ohdsi-workspace/ir/<slug:view_type>/<int:sc_id>/<int:ir_id>/<int:read_only>',
         views.incidence_rates, name='edit_ir'),
    path('ohdsi-workspace/char', views.characterizations, name='add_char'),
    path('ohdsi-workspace/char/<int:sc_id>/<int:char_id>', views.characterizations, name='edit_char'),
    path('ohdsi-workspace/char/<int:sc_id>/<int:char_id>/<int:read_only>', views.characterizations, name='edit_char'),
    path('ohdsi-workspace/char/<slug:view_type>/<int:sc_id>/<int:char_id>', views.characterizations, name='edit_char'),
    path('ohdsi-workspace/char/<slug:view_type>/<int:sc_id>/<int:char_id>/<int:read_only>',
         views.characterizations, name='edit_char'),
    path('ohdsi-workspace/cp', views.pathways, name='add_cp'),
    path('ohdsi-workspace/cp/<int:sc_id>/<int:cp_id>', views.pathways, name='edit_cp'),
    path('ohdsi-workspace/cp/<int:sc_id>/<int:cp_id>/<int:read_only>', views.pathways, name='edit_cp'),
    path('ajax/synonyms', views.get_synonyms, name='drugs_synonyms'),
    path('ajax/filter-whole-set', views.filter_whole_set, name='filter_whole_set'),
    path('ajax/all-drugs', views.get_all_drugs, name='get_all_drugs'),
    path('ajax/medDRA-tree', views.get_medDRA_tree, name='get_medDRA_tree'),
    path('ajax/conds-nodes-ids', views.get_conditions_nodes_ids, name='conds_nodes_ids'),
    path('ajax/gen-char-analysis', views.gen_char_analysis, name='gen_char_analysis'),
    path('ajax/gen-cp-analysis', views.gen_cp_analysis, name='gen_cp_analysis'),
    path('ajax/del-ir-analysis', views.del_ir_analysis, name='del_ir_analysis'),
    path('ajax/gen-ir-analysis', views.gen_ir_analysis, name='gen_ir_analysis'),
    path('ajax/get-note-content', views.get_note_content, name='get_note_content'),
    path('ajax/get-note', views.get_note, name='get_note'),
    path('ajax/openfda-screenshots-exist', views.openfda_screenshots_exist, name='openfda-screenshots-exist'),
    path('OpenFDAWorkspace/', views.OpenFDAWorkspace, name='OpenFDAWorkspace'),
    path('OpenFDAWorkspace/<int:scenario_id>', views.OpenFDAWorkspace, name='OpenFDAWorkspace'),
    path('ohdsi-workspace/<int:scenario_id>', views.ohdsi_workspace, name='ohdsi_workspace'),
    path('LiteratureWorkspace/<int:scenario_id>', views.pubMed_view, name='LiteratureWorkspace'),
    path('LiteratureWorkspace/<int:scenario_id>/<int:page_id>', views.pubMed_view, name='LiteratureWorkspace'),
    path('LiteratureWorkspace/<int:scenario_id>/<str:first>/<str:end>', views.pubMed_view, name='LiteratureWorkspace'),
    path('LiteratureWorkspace/<int:scenario_id>/<str:first>/<str:end>/<int:page_id>', views.pubMed_view, name='LiteratureWorkspace'),
    path("LiteratureWorkspace/paper_notes_view/<int:scenario_id>", views.paper_notes_view, name='paper_notes'),
    path("LiteratureWorkspace/paper_notes_view/<int:scenario_id>/<int:page_id>", views.paper_notes_view, name='paper_notes'),
    path("LiteratureWorkspace/paper_notes_view/<int:scenario_id>/<str:first>/<str:end>", views.paper_notes_view, name='paper_notes'),
    path("LiteratureWorkspace/paper_notes_view/<int:scenario_id>/<str:first>/<str:end>/<int:page_id>", views.paper_notes_view, name='paper_notes'),
    path("ajax/save_pubmed_input/", views.save_pubmed_input, name='save_pubmed_input'),
    path("ajax/mendeley_login", views.is_logged_in, name='mendeley_login'),
    path("edit-scenario/ajax/mendeley_login", views.is_logged_in, name='mendeley_login'),
    path('social-auth/', include('social_django.urls', namespace='social_mendeley')),
    # path("notes/<int:scenario_id>/<int:workspace_id>", views.keep_notes, name='keep_notes'),
    path("notes/<str:ws_id>/<str:wsview_id>", views.keep_notes, name='keep_notes'),
    path("notes/<int:sc_id>/<str:ws_id>/<str:wsview_id>", views.keep_notes, name='keep_notes'),
    path("aggr-notes/<str:lang>", views.aggregated_notes, name='aggregated_notes'),
    path("notes/<int:sc_id>", views.allnotes, name='allnotes'),
    path("notes", views.allnotes, name='allnotes'),
    path("del-note", views.delete_note_obj, name='del_note'),
    path("social-media/<int:sc_id>", views.social_media, name='social_media_workspace'),

    path("final_report", views.final_report, name='final_report'),
    path('final_report/<int:scenario_id>', views.final_report, name='final_report'),
    path("ajax/report_pdf", views.report_pdf, name='ajax_report_pdf'),
    path("report_pdf/<int:scenario_id>", views.report_pdf, name='report_pdf'),
    path("report_pdf/<int:scenario_id>/<str:report_notes>", views.report_pdf, name='report_pdf'),
    path("report_pdf/<int:scenario_id>/<str:report_notes>/<str:extra_notes>", views.report_pdf, name='report_pdf'),
    path("report_pdf/<int:scenario_id>/<str:report_notes>/<str:extra_notes>/<str:pub_titles>", views.report_pdf,
         name='report_pdf'),
    path("report_pdf/<int:scenario_id>/<str:report_notes>/<str:extra_notes>/<str:pub_titles>/<str:pub_notes>",
         views.report_pdf, name='report_pdf'),
    path("ajax/print_report", views.print_report, name='ajax_print_report'),
    path("ic_management_workspace", views.ic_management_workspace, name='ic_management_workspace'),
    path("ic_management_workspace/new_ic_cor", views.new_ic_cor, name='new_ic_cor'),
    path("ic_management_workspace/new_ic_cor/<int:quest_id>/<str:indiv_case_id>/<int:sc_id>/", views.new_ic_cor,
         name='new_ic_cor'),
    path("ic_management_workspace/new_ic_cor/questionnaire", views.questionnaire, name='questionnaire'),
    path("ic_management_workspace/new_ic_cor/questionnaire/<str:indiv_case_id>/<int:sc_id>/", views.questionnaire,
         name='questionnaire'),

    path("ic_management_workspace/new_ic_cor/answers_detail/<int:pk>/<int:scen_id>/<str:ic_id>/",
         views.answers_detail, name='answers_detail'),
    path("ajax/new_ic_cor", views.new_ic_cor, name='ajax_new_ic_cor'),
    path("ajax/questionnaire", views.questionnaire, name='ajax_questionnaire'),
    path("ajax/retr-del-session-pmcvars", views.retr_del_session_pmcvars, name='ajax_retr_del_ses_pmcvars'),
    path("ajax/get-updated-scenarios-ids", views.get_updated_scenarios_ids, name='ajax_get_updated_scenarios_ids'),
    path("ic_management_workspace/indiv_case_history/<str:indiv_case_pk>", views.indiv_case_history,
         name='indiv_case_history'),
    path("ajax/get-popover-content", views.get_popover_content, name='get_popover_content'),

    path("ajax/check-twitter-shots", views.check_twitter_shots, name='ajax_check_twitter_shots'),

    # Permission denied
    path('denied', views.unauthorized, name='unauthorized'),
]


if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

