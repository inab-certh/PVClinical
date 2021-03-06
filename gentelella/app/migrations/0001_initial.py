# Generated by Django 3.2.8 on 2022-02-22 10:22

import ckeditor.fields
from django.conf import settings
import django.core.validators
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='CaseToQuestionnaire',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
            ],
        ),
        migrations.CreateModel(
            name='CaseToScenario',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
            ],
        ),
        migrations.CreateModel(
            name='Condition',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(blank=True, default='', max_length=50, null=True, validators=[django.core.validators.RegexValidator(code='invalid_disease', message='Όνομα πάθησης', regex='^[\\w\\-,\\(\\) ]*$')])),
                ('code', models.CharField(blank=True, default='', max_length=8, null=True, validators=[django.core.validators.RegexValidator(code='invalid_disease', message='Κωδικοποίηση πάθησης', regex='^\\d{8}$')])),
            ],
        ),
        migrations.CreateModel(
            name='Drug',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(blank=True, default='', max_length=50, null=True, validators=[django.core.validators.RegexValidator(code='invalid_drug', message='Όνομα φαρμάκου', regex='^[\\w\\-,\\(\\) ]*$')])),
                ('code', models.CharField(blank=True, default='', max_length=7, null=True, validators=[django.core.validators.RegexValidator(code='invalid_drug', message='Κωδικοποίηση φαρμάκου', regex='^[a-zA-Z]{1}[0-9]{2}[a-zA-Z]{2}[0-9]{2}$')])),
            ],
        ),
        migrations.CreateModel(
            name='Notes',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('content', ckeditor.fields.RichTextField(blank=True, default='', null=True)),
                ('workspace', models.PositiveSmallIntegerField(validators=[django.core.validators.MinValueValidator(1), django.core.validators.MaxValueValidator(5)])),
                ('wsview', models.TextField(default='')),
                ('note_datetime', models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name='PatientCase',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('patient_id', models.CharField(default='', max_length=500, validators=[django.core.validators.RegexValidator('\\d{4}[A-Z]{3}\\d{7}', 'Παράδειγμα ορθού αναγνωριστικού: 0001PGH0000001')])),
                ('timestamp', models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name='PubMed',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('pid', models.CharField(default='', max_length=70)),
                ('title', models.CharField(default='', max_length=500)),
                ('pubdate', models.CharField(default='', max_length=400)),
                ('abstract', models.TextField(blank=True, null=True)),
                ('authors', models.CharField(default='', max_length=400)),
                ('url', models.CharField(default='', max_length=100)),
                ('relevance', models.CharField(choices=[(True, 'Relevant'), (False, 'Irrelevant'), ('Not sure', 'Not sure')], default='', max_length=20, null=True)),
                ('created', models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name='Questionnaire',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('q1', models.BooleanField(default=None, null=True)),
                ('q2', models.BooleanField(default=None, null=True)),
                ('q3', models.BooleanField(default=None, null=True)),
                ('q4', models.BooleanField(default=None, null=True)),
                ('q5', models.BooleanField(default=None, null=True)),
                ('q6', models.BooleanField(default=None, null=True)),
                ('q7', models.BooleanField(default=None, null=True)),
                ('q8', models.BooleanField(default=None, null=True)),
                ('q9', models.BooleanField(default=None, null=True)),
                ('q10', models.BooleanField(default=None, null=True)),
                ('result', models.CharField(max_length=200)),
            ],
        ),
        migrations.CreateModel(
            name='Status',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('status', models.CharField(choices=[('CREATING', 'Υπό δημιουργία'), ('RUNNING', 'Σε εξέλιξη'), ('COMPLETED', 'Ολοκληρώθηκε')], default='CREATING', max_length=9, unique=True, verbose_name='Κατάσταση: ')),
            ],
            options={
                'ordering': ['id'],
            },
        ),
        migrations.CreateModel(
            name='Scenario',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(blank=True, default='', max_length=50, null=True, validators=[django.core.validators.RegexValidator(code='invalid_title', message='Τίτλος Σεναρίου', regex='^[\\w\\-,\\(\\) ]*$')])),
                ('timestamp', models.DateTimeField(auto_now_add=True)),
                ('conditions', models.ManyToManyField(blank=True, default=None, related_name='conditions', to='app.Condition', verbose_name='conditions')),
                ('drugs', models.ManyToManyField(blank=True, default=None, related_name='drugs', to='app.Drug', verbose_name='drugs')),
                ('owner', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
                ('status', models.ForeignKey(default=1, on_delete=django.db.models.deletion.PROTECT, to='app.status')),
            ],
        ),
        migrations.AddConstraint(
            model_name='questionnaire',
            constraint=models.UniqueConstraint(fields=('q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7', 'q8', 'q9', 'q10'), name='unique_questionnaire'),
        ),
        # migrations.AddField(
        #     model_name='pubmed',
        #     name='notes',
        #     field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.CASCADE, to='app.notes'),
        # ),
        migrations.AddField(
            model_name='pubmed',
            name='scenario_id',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='app.scenario'),
        ),
        migrations.AddField(
            model_name='pubmed',
            name='user',
            field=models.ForeignKey(default=1, on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL),
        ),
        migrations.AddField(
            model_name='patientcase',
            name='questionnaires',
            field=models.ManyToManyField(default=None, related_name='questionnaires', through='app.CaseToQuestionnaire', to='app.Questionnaire', verbose_name='questionnaires'),
        ),
        migrations.AddField(
            model_name='patientcase',
            name='scenarios',
            field=models.ManyToManyField(default=None, related_name='scenarios', through='app.CaseToScenario', to='app.Scenario', verbose_name='scenarios'),
        ),
        migrations.AddField(
            model_name='patientcase',
            name='user',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL),
        ),
        migrations.AddField(
            model_name='notes',
            name='scenario',
            field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.CASCADE, to='app.scenario'),
        ),
        migrations.AddField(
            model_name='notes',
            name='user',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL),
        ),
        migrations.AddConstraint(
            model_name='drug',
            constraint=models.UniqueConstraint(fields=('name', 'code'), name='unique_drug'),
        ),
        migrations.AddConstraint(
            model_name='condition',
            constraint=models.UniqueConstraint(fields=('name', 'code'), name='unique_condition'),
        ),
        migrations.AddField(
            model_name='casetoscenario',
            name='pcase',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='app.patientcase'),
        ),
        migrations.AddField(
            model_name='casetoscenario',
            name='scenario',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='app.scenario'),
        ),
        migrations.AddField(
            model_name='casetoquestionnaire',
            name='pcaseq',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='app.patientcase'),
        ),
        migrations.AddField(
            model_name='casetoquestionnaire',
            name='questionnaire',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='app.questionnaire'),
        ),
        migrations.AddConstraint(
            model_name='scenario',
            constraint=models.UniqueConstraint(fields=('title', 'owner'), name='unique_scenario'),
        ),
        migrations.AddConstraint(
            model_name='pubmed',
            constraint=models.UniqueConstraint(fields=('pid', 'user', 'scenario_id'), name='unique_article'),
        ),
        migrations.AddConstraint(
            model_name='patientcase',
            constraint=models.UniqueConstraint(fields=('patient_id', 'timestamp'), name='unique_patientcase'),
        ),
        migrations.AddConstraint(
            model_name='notes',
            constraint=models.UniqueConstraint(fields=('user', 'scenario', 'workspace', 'wsview'), name='unique_note'),
        ),
        migrations.AddConstraint(
            model_name='casetoscenario',
            constraint=models.UniqueConstraint(fields=('scenario', 'pcase'), name='unique_pcase_scenario'),
        ),
        migrations.AddConstraint(
            model_name='casetoquestionnaire',
            constraint=models.UniqueConstraint(fields=('questionnaire', 'pcaseq'), name='unique_questionnaire_pcaseq'),
        ),
    ]
