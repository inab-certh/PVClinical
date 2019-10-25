from django.db import models
from django.db.models.signals import post_save
from django.db.models.signals import pre_save
from django.dispatch import receiver
from django.contrib.auth.models import User
# Create your models here.

class CustomUser(models.Model):
    user = models.OneToOneField(User,
                                on_delete=models.CASCADE,
                                related_name="cuser")

    force_password_change = models.BooleanField(default=True)

    def __str__(self):
        full_name = self.user.get_full_name()
        return full_name or self.user.username

@receiver(post_save, sender=User)
def create_user_profile_signal(sender, instance, created, **kwargs):
    if created:
        CustomUser.objects.create(user=instance)


@receiver(pre_save, sender=User)
def password_change_signal(sender, instance, **kwargs):
    try:
        user = User.objects.get(username=instance.username)
        if user.password != instance.password:
            cuser = user.cuser
            cuser.force_password_change = False
            cuser.save()

    except User.DoesNotExist:
        pass

