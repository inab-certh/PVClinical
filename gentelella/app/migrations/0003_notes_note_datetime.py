# Generated by Django 2.2.6 on 2021-01-28 11:17

from django.db import migrations, models
import django.utils.timezone


class Migration(migrations.Migration):

    dependencies = [
        ('app', '0002_auto_20210127_1707'),
    ]

    operations = [
        migrations.AddField(
            model_name='notes',
            name='note_datetime',
            field=models.DateTimeField(auto_now_add=True, default=django.utils.timezone.now),
            preserve_default=False,
        ),
    ]
