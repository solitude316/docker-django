FROM ubuntu:latest
RUN apt-get update
RUN apt-get install -y curl python3 python3-dev python3-distutils nginx vim telnet net-tools build-essential \
	postgresql-client postgresql-server-dev-10 
RUN ln -s /usr/bin/python3 /usr/bin/python

#install pip
RUN curl https://bootstrap.pypa.io/get-pip.py | python -
RUN pip install uwsgi
RUN pip install virtualenv
RUN pip install django

# create porject
RUN django-admin.py startproject mysite /var/www/html

RUN echo 'STATIC_ROOT = os.path.join(BASE_DIR, "static/")' >> /var/www/html/mysite/settings.py
RUN python /var/www/html/manage.py collectstatic

# create virtualenv

COPY ./configs/requirement.txt /tmp/
RUN mkdir -p /var/venv/django
RUN virtualenv /var/venv/django
RUN /bin/bash -c "source /var/venv/django/bin/activate && pip install -r /tmp/requirement.txt"

RUN mkdir -p /etc/uwsgi/vassals
COPY ./configs/mysite_uwsgi.ini /etc/uwsgi/vassals/

RUN mkdir -p /var/run/uwsgi/
RUN chown -R www-data:www-data /var/run/uwsgi/

COPY ./configs/django.conf /etc/nginx/sites-available/
RUN rm /etc/nginx/sites-enabled/default
RUN ln -s /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled/

COPY ./configs/uwsgi_params /etc/nginx/
COPY ./configs/mysite_uwsgi.ini /etc/uwsgi/vassals/
COPY ./configs/start.sh /
RUN chmod +x /start.sh

EXPOSE 80 443
ENTRYPOINT /bin/sh -x /start.sh && nginx -g 'daemon off;' 
