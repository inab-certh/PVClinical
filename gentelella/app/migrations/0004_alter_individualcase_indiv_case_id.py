# Generated by Django 3.2.8 on 2022-05-10 12:57

import django.core.validators
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('app', '0003_auto_20220321_1312'),
    ]

    operations = [
        migrations.AlterField(
            model_name='individualcase',
            name='indiv_case_id',
            field=models.CharField(default='', max_length=500, validators=[django.core.validators.RegexValidator('^\\d+$', 'Παράδειγμα ορθού αναγνωριστικού: 10029250')]),
        ),
    ]
