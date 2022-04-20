# Generated by Django 2.2.6 on 2019-12-12 11:12

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('app', '0002_auto_20191128_1321'),
    ]

    operations = [
        migrations.AlterField(
            model_name='scenario',
            name='conditions',
            field=models.ManyToManyField(blank=True, default=None, related_name='conditions', to='app.Condition', verbose_name='conditions'),
        ),
        migrations.AlterField(
            model_name='scenario',
            name='drugs',
            field=models.ManyToManyField(blank=True, default=None, related_name='drugs', to='app.Drug', verbose_name='drugs'),
        ),
    ]