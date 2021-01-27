# Generated by Django 2.2.6 on 2020-11-25 08:30

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('app', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='PubMed',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('pid', models.CharField(default='', max_length=70)),
                ('title', models.CharField(default='', max_length=500)),
                ('pubdate', models.CharField(default='', max_length=400)),
                ('abstract', models.TextField(blank=True, null=True)),
                ('authors', models.CharField(default='', max_length=400)),
                ('url', models.CharField(default='', max_length=100)),
                ('relevance', models.CharField(choices=[(True, 'Relevant'), (False, 'Irrelevant'), ('Not sure', 'Not sure')], default='', max_length=20, null=True)),
                ('notes', models.TextField(blank=True, null=True)),
                ('scenario_id', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='app.Scenario')),
                ('user', models.ForeignKey(default=1, on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.AddConstraint(
            model_name='pubmed',
            constraint=models.UniqueConstraint(fields=('pid', 'user', 'scenario_id'), name='unique_article'),
        ),
    ]
